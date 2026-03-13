require "rails_helper"

RSpec.describe CategoryService do
  let(:service) { described_class.new }

  describe "#create" do
    context "有効なパラメータの場合" do
      it "カテゴリを作成し success: true を返す" do
        result = service.create(name: "PC機器")

        expect(result[:success]).to be true
        expect(result[:category]).to be_persisted
        expect(result[:category].name).to eq("PC機器")
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

    context "名前が重複している場合" do
      before { create(:category, name: "家具") }

      it "success: false を返す" do
        result = service.create(name: "家具")

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to include("カテゴリ名")
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

    context "名前が他のカテゴリと重複する場合" do
      before { create(:category, name: "既存カテゴリ") }

      it "success: false を返す" do
        result = service.update(category: category, params: { name: "既存カテゴリ" })

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end
  end

  describe "#destroy" do
    context "備品が紐づいていない場合" do
      let(:category) { create(:category) }

      it "カテゴリを削除し success: true を返す" do
        result = service.destroy(category: category)

        expect(result[:success]).to be true
        expect(Category.find_by(id: category.id)).to be_nil
      end
    end

    context "備品が紐づいている場合" do
      let(:category) { create(:category) }
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
  end
end
