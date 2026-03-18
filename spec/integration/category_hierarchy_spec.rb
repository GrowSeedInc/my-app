require "rails_helper"

# カテゴリ階層→備品登録→検索→削除の統合テスト
RSpec.describe "カテゴリ階層と備品の統合フロー" do
  let(:category_service) { CategoryService.new }
  let(:search_service)   { SearchService.new }

  # ─── 階層作成→備品登録→検索→削除フロー ───────────────────────────────────
  describe "大→中→小分類の作成から備品登録・検索・削除まで" do
    let!(:major)  { create(:category, name: "PC機器", level: :major) }
    let!(:medium) { create(:category, :medium, name: "ノートPC類", parent: major) }
    let!(:minor)  { create(:category, :minor, name: "ThinkPad", parent: medium) }

    context "備品に小分類を紐付けて登録する" do
      let!(:equipment) { create(:equipment, name: "ThinkPad X1", management_number: "TP-001", category: minor) }

      it "備品が小分類に紐付いている" do
        expect(equipment.category).to eq(minor)
        expect(equipment.category.minor?).to be true
      end

      it "備品から親カテゴリ階層を辿れる" do
        expect(equipment.category.parent).to eq(medium)
        expect(equipment.category.parent.parent).to eq(major)
      end

      context "SearchService で大分類フィルタを使って備品を検索する" do
        it "大分類 ID で配下の全備品がヒットする" do
          result = search_service.search_equipments(category_major_id: major.id)
          expect(result.records.map(&:name)).to include("ThinkPad X1")
        end

        it "中分類 ID で配下の備品がヒットする" do
          result = search_service.search_equipments(category_medium_id: medium.id)
          expect(result.records.map(&:name)).to include("ThinkPad X1")
        end

        it "小分類 ID で直接一致する備品がヒットする" do
          result = search_service.search_equipments(category_minor_id: minor.id)
          expect(result.records.map(&:name)).to include("ThinkPad X1")
        end

        it "別の大分類 ID ではヒットしない" do
          other_major = create(:category, name: "家具", level: :major)
          result = search_service.search_equipments(category_major_id: other_major.id)
          expect(result.records.map(&:name)).not_to include("ThinkPad X1")
        end
      end

      context "備品が存在する小分類は削除できない" do
        it "CategoryService#destroy が :has_equipments エラーを返す" do
          result = category_service.destroy(category: minor)
          expect(result[:success]).to be false
          expect(result[:error]).to eq(:has_equipments)
        end

        it "小分類レコードが残っている" do
          category_service.destroy(category: minor)
          expect(Category.find_by(id: minor.id)).to be_present
        end
      end

      context "論理削除済み備品もDBに残るため削除はブロックされる" do
        before { equipment.discard }

        it "discard 後も CategoryService#destroy は失敗する" do
          result = category_service.destroy(category: minor)
          expect(result[:success]).to be false
          expect(result[:error]).to eq(:has_equipments)
        end
      end

      context "備品が存在しない小分類は削除できる" do
        let!(:empty_minor) { create(:category, :minor, name: "空の小分類", parent: medium) }

        it "CategoryService#destroy が成功する" do
          result = category_service.destroy(category: empty_minor)
          expect(result[:success]).to be true
        end

        it "小分類レコードが削除される" do
          category_service.destroy(category: empty_minor)
          expect(Category.find_by(id: empty_minor.id)).to be_nil
        end
      end
    end

    context "大分類配下に複数の中分類・小分類・備品が存在する場合" do
      let!(:medium2) { create(:category, :medium, name: "デスクトップ類", parent: major) }
      let!(:minor2)  { create(:category, :minor, name: "iMac", parent: medium2) }
      let!(:eq1)     { create(:equipment, name: "ThinkPad X1",  management_number: "TP-001", category: minor) }
      let!(:eq2)     { create(:equipment, name: "iMac 24inch",  management_number: "IM-001", category: minor2) }

      it "大分類フィルタで全配下備品（複数の中分類をまたぐ）がヒットする" do
        result = search_service.search_equipments(category_major_id: major.id)
        names = result.records.map(&:name)
        expect(names).to include("ThinkPad X1", "iMac 24inch")
      end

      it "中分類フィルタで絞り込むと該当中分類のみの備品が返る" do
        result = search_service.search_equipments(category_medium_id: medium.id)
        names = result.records.map(&:name)
        expect(names).to include("ThinkPad X1")
        expect(names).not_to include("iMac 24inch")
      end
    end

    context "小分類が存在する中分類は削除できない" do
      it "CategoryService#destroy が :has_children エラーを返す" do
        result = category_service.destroy(category: medium)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_children)
      end
    end

    context "中分類が存在する大分類は削除できない" do
      it "CategoryService#destroy が :has_children エラーを返す" do
        result = category_service.destroy(category: major)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_children)
      end
    end
  end

  # ─── 階層カテゴリの CategoryService CRUD フロー ───────────────────────────
  describe "CategoryService を通じた階層の段階的作成" do
    it "大→中→小分類の順で作成できる" do
      major_result = category_service.create(name: "AV機器", level: :major)
      expect(major_result[:success]).to be true
      major = major_result[:category]

      medium_result = category_service.create(name: "プロジェクター類", level: :medium, parent_id: major.id)
      expect(medium_result[:success]).to be true
      medium = medium_result[:category]

      minor_result = category_service.create(name: "短焦点プロジェクター", level: :minor, parent_id: medium.id)
      expect(minor_result[:success]).to be true
      minor = minor_result[:category]

      expect(minor.parent).to eq(medium)
      expect(minor.parent.parent).to eq(major)
    end

    it "中分類は大分類以外を親に指定できない" do
      major = create(:category, level: :major)
      medium = create(:category, :medium, parent: major)

      result = category_service.create(name: "不正な中分類", level: :medium, parent_id: medium.id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:validation_failed)
    end

    it "小分類は中分類以外を親に指定できない" do
      major = create(:category, level: :major)

      result = category_service.create(name: "不正な小分類", level: :minor, parent_id: major.id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:validation_failed)
    end
  end
end
