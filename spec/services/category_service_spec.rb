require "rails_helper"

RSpec.describe CategoryService do
  let(:service) { described_class.new }

  describe "#create" do
    context "大分類を作成する場合" do
      it "level: :major で作成し success: true を返す" do
        result = service.create(name: "PC機器", level: :major)

        expect(result[:success]).to be true
        expect(result[:category]).to be_persisted
        expect(result[:category].name).to eq("PC機器")
        expect(result[:category]).to be_major
      end

      it "parent_id を省略して大分類を作成できる" do
        result = service.create(name: "家具")

        expect(result[:success]).to be true
        expect(result[:category]).to be_major
        expect(result[:category].parent_id).to be_nil
      end
    end

    context "中分類を作成する場合" do
      let(:major) { create(:category) }

      it "level: :medium, parent_id: major.id で作成し success: true を返す" do
        result = service.create(name: "ノートPC", level: :medium, parent_id: major.id)

        expect(result[:success]).to be true
        expect(result[:category]).to be_persisted
        expect(result[:category]).to be_medium
        expect(result[:category].parent).to eq(major)
      end

      it "parent_id なしで中分類を作成しようとすると success: false を返す" do
        result = service.create(name: "ノートPC", level: :medium)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end

    context "小分類を作成する場合" do
      let(:major) { create(:category) }
      let(:medium) { create(:category, :medium, parent: major) }

      it "level: :minor, parent_id: medium.id で作成し success: true を返す" do
        result = service.create(name: "ThinkPad", level: :minor, parent_id: medium.id)

        expect(result[:success]).to be true
        expect(result[:category]).to be_persisted
        expect(result[:category]).to be_minor
        expect(result[:category].parent).to eq(medium)
      end
    end

    context "名前が空欄の場合" do
      it "success: false を返す" do
        result = service.create(name: "")

        expect(result[:success]).to be false
        expect(result[:category]).not_to be_persisted
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to be_present
      end
    end

    context "同一親スコープ内で名前が重複している場合" do
      let(:major) { create(:category, name: "PC機器") }
      before { create(:category, :medium, name: "ノートPC", parent: major) }

      it "同一親内で重複する場合 success: false を返す" do
        result = service.create(name: "ノートPC", level: :medium, parent_id: major.id)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to be_present
      end

      it "別の親なら同名でも作成できる" do
        other_major = create(:category, name: "AV機器")
        result = service.create(name: "ノートPC", level: :medium, parent_id: other_major.id)

        expect(result[:success]).to be true
      end
    end

    context "大分類名がグローバルに重複している場合" do
      before { create(:category, name: "家具") }

      it "success: false を返す" do
        result = service.create(name: "家具")

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to be_present
      end
    end
  end

  describe "#update" do
    let(:category) { create(:category, name: "旧カテゴリ名") }

    context "有効なパラメータの場合" do
      it "カテゴリを更新し success: true を返す" do
        result = service.update(category: category, params: { name: "新カテゴリ名" })

        expect(result[:success]).to be true
        expect(result[:category].name).to eq("新カテゴリ名")
      end
    end

    context "名前が空欄の場合" do
      it "success: false を返す" do
        result = service.update(category: category, params: { name: "" })

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to be_present
      end
    end

    context "名前が他の大分類と重複する場合" do
      before { create(:category, name: "既存カテゴリ") }

      it "success: false を返す" do
        result = service.update(category: category, params: { name: "既存カテゴリ" })

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end
  end

  describe "#destroy" do
    context "備品も子カテゴリも紐づいていない場合" do
      let(:category) { create(:category) }

      it "カテゴリを削除し success: true を返す" do
        result = service.destroy(category: category)

        expect(result[:success]).to be true
        expect(Category.find_by(id: category.id)).to be_nil
      end
    end

    context "備品が紐づいている場合（小分類）" do
      let(:category) { create(:category, :minor) }
      before { create(:equipment, category: category) }

      it "削除をブロックし success: false を返す" do
        result = service.destroy(category: category)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_equipments)
        expect(result[:message]).to include("備品")
      end

      it "カテゴリは削除されない" do
        service.destroy(category: category)
        expect(Category.find_by(id: category.id)).to be_present
      end
    end

    context "子カテゴリが存在する場合（大分類）" do
      let(:major) { create(:category) }
      before { create(:category, :medium, parent: major) }

      it "削除をブロックし success: false を返す" do
        result = service.destroy(category: major)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_children)
        expect(result[:message]).to include("子カテゴリ")
      end

      it "カテゴリは削除されない" do
        service.destroy(category: major)
        expect(Category.find_by(id: major.id)).to be_present
      end
    end
  end
end
