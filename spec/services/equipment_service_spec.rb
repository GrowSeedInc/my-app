require "rails_helper"

RSpec.describe EquipmentService do
  let(:service) { described_class.new }
  let(:category) { create(:category) }

  describe "#create" do
    context "有効なパラメータの場合" do
      it "備品を作成し success: true を返す" do
        result = service.create(
          name: "ノートPC",
          management_number: "EQ-001",
          total_count: 5,
          description: "テスト用PC"
        )

        expect(result[:success]).to be true
        expect(result[:equipment]).to be_persisted
        expect(result[:equipment].name).to eq("ノートPC")
      end

      it "available_countが指定されない場合はtotal_countと同じ値になる" do
        result = service.create(
          name: "椅子",
          management_number: "EQ-002",
          total_count: 10
        )

        expect(result[:success]).to be true
        expect(result[:equipment].available_count).to eq(10)
      end

      it "カテゴリを関連付けて作成できる" do
        result = service.create(
          name: "モニター",
          management_number: "EQ-003",
          total_count: 3,
          category_id: category.id
        )

        expect(result[:success]).to be true
        expect(result[:equipment].category).to eq(category)
      end
    end

    context "管理番号が重複している場合" do
      before { create(:equipment, management_number: "EQ-DUP") }

      it "success: false を返す" do
        result = service.create(
          name: "別の備品",
          management_number: "EQ-DUP",
          total_count: 1
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
        expect(result[:message]).to include("管理番号")
      end
    end

    context "必須項目が不足している場合" do
      it "名称がない場合は success: false を返す" do
        result = service.create(
          name: "",
          management_number: "EQ-004",
          total_count: 1
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end
  end

  describe "#update" do
    let(:equipment) { create(:equipment, name: "旧名称", total_count: 5, available_count: 5) }

    context "有効なパラメータの場合" do
      it "備品情報を更新し success: true を返す" do
        result = service.update(
          equipment: equipment,
          params: { name: "新名称", description: "更新後の説明" }
        )

        expect(result[:success]).to be true
        expect(result[:equipment].name).to eq("新名称")
        expect(result[:equipment].description).to eq("更新後の説明")
      end

      it "updated_atが自動更新される" do
        original_updated_at = equipment.updated_at
        travel_to(1.second.from_now) do
          service.update(equipment: equipment, params: { name: "変更後" })
        end

        expect(equipment.reload.updated_at).to be > original_updated_at
      end
    end

    context "管理番号が重複する場合" do
      before { create(:equipment, management_number: "EQ-OTHER") }

      it "success: false を返す" do
        result = service.update(
          equipment: equipment,
          params: { management_number: "EQ-OTHER" }
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end
  end

  describe "#destroy" do
    context "貸出中でない場合" do
      let(:equipment) { create(:equipment) }

      it "論理削除し success: true を返す" do
        result = service.destroy(equipment: equipment)

        expect(result[:success]).to be true
        expect(equipment.reload.discarded?).to be true
      end

      it "貸出履歴レコードは残る" do
        loan = create(:loan, equipment: equipment, status: :returned)

        result = service.destroy(equipment: equipment)

        expect(result[:success]).to be true
        expect(Loan.find(loan.id)).to be_present
      end
    end

    context "貸出中（active）の備品の場合" do
      let(:equipment) { create(:equipment, available_count: 0) }
      before { create(:loan, equipment: equipment, status: :active) }

      it "削除をブロックし success: false を返す" do
        result = service.destroy(equipment: equipment)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_active_loans)
        expect(result[:message]).to include("貸出中")
      end

      it "備品は削除されない" do
        service.destroy(equipment: equipment)
        expect(equipment.reload.discarded?).to be false
      end
    end

    context "延滞中（overdue）の備品の場合" do
      let(:equipment) { create(:equipment, available_count: 0) }
      before { create(:loan, equipment: equipment, status: :overdue) }

      it "削除をブロックし success: false を返す" do
        result = service.destroy(equipment: equipment)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:has_active_loans)
      end
    end
  end
end
