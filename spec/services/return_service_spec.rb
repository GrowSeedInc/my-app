require "rails_helper"

RSpec.describe ReturnService do
  let(:service) { described_class.new }
  let(:actor)   { create(:user) }

  describe "#process_return" do
    context "貸出中（active）のローンの場合" do
      let(:equipment) { create(:equipment, total_count: 3, available_count: 2) }
      let(:loan) { create(:loan, equipment: equipment, status: :active) }

      it "success: true を返す" do
        result = service.process_return(loan_id: loan.id, actor: actor)
        expect(result[:success]).to be true
      end

      it "ステータスを returned に変更する" do
        service.process_return(loan_id: loan.id, actor: actor)
        expect(loan.reload.status).to eq("returned")
      end

      it "actual_return_date に本日の日付を記録する" do
        service.process_return(loan_id: loan.id, actor: actor)
        expect(loan.reload.actual_return_date).to eq(Date.today)
      end

      it "備品の貸出可能数を1増加させる" do
        expect {
          service.process_return(loan_id: loan.id, actor: actor)
        }.to change { equipment.reload.available_count }.by(1)
      end

      it "Loan更新とEquipment更新は同一トランザクション内で実行される" do
        allow_any_instance_of(Equipment).to receive(:increment!).and_raise(ActiveRecord::StatementInvalid)

        expect {
          service.process_return(loan_id: loan.id, actor: actor)
        }.to raise_error(ActiveRecord::StatementInvalid)

        expect(loan.reload.status).to eq("active")
      end
    end

    context "延滞中（overdue）のローンの場合" do
      let(:equipment) { create(:equipment, total_count: 3, available_count: 1) }
      let(:loan) { create(:loan, equipment: equipment, status: :overdue) }

      it "success: true を返す" do
        result = service.process_return(loan_id: loan.id, actor: actor)
        expect(result[:success]).to be true
      end

      it "ステータスを returned に変更する" do
        service.process_return(loan_id: loan.id, actor: actor)
        expect(loan.reload.status).to eq("returned")
      end

      it "備品の貸出可能数を1増加させる" do
        expect {
          service.process_return(loan_id: loan.id, actor: actor)
        }.to change { equipment.reload.available_count }.by(1)
      end
    end

    context "承認待ち（pending_approval）のローンの場合" do
      let(:loan) { create(:loan, status: :pending_approval) }

      it "success: false を返す" do
        result = service.process_return(loan_id: loan.id, actor: actor)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:invalid_status)
        expect(result[:message]).to include("返却処理できません")
      end

      it "ステータスは変わらない" do
        service.process_return(loan_id: loan.id, actor: actor)
        expect(loan.reload.status).to eq("pending_approval")
      end
    end

    context "返却済み（returned）のローンの場合" do
      let(:loan) { create(:loan, status: :returned) }

      it "success: false を返す" do
        result = service.process_return(loan_id: loan.id, actor: actor)
        expect(result[:success]).to be false
        expect(result[:error]).to eq(:invalid_status)
      end
    end
  end
end
