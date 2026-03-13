require "rails_helper"

RSpec.describe LoanService do
  let(:service) { described_class.new }
  let(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }

  describe "#create" do
    let(:equipment) { create(:equipment, total_count: 3, available_count: 3) }
    let(:start_date) { Date.today }
    let(:expected_return_date) { Date.today + 7 }

    context "在庫がある場合（通知含む）" do
      it "貸出成功時に loan_confirmation メールをキューに積む" do
        expect {
          service.create(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.to have_enqueued_mail(LoanMailer, :loan_confirmation)
      end
    end

    context "在庫がある場合" do
      it "貸出レコードを作成し success: true を返す" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be true
        expect(result[:loan]).to be_persisted
        expect(result[:loan].user).to eq(member)
        expect(result[:loan].equipment).to eq(equipment)
      end

      it "初期ステータスは pending_approval になる" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:loan].status).to eq("pending_approval")
      end

      it "備品の貸出可能数が1減少する" do
        expect {
          service.create(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.to change { equipment.reload.available_count }.by(-1)
      end

      it "同時申請でも排他ロックにより在庫を正確に管理する" do
        equipment2 = create(:equipment, total_count: 1, available_count: 1)

        results = 2.times.map do
          service.create(
            user: create(:user),
            equipment_id: equipment2.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        end

        successes = results.count { |r| r[:success] }
        failures  = results.count { |r| !r[:success] }
        expect(successes).to eq(1)
        expect(failures).to eq(1)
        expect(equipment2.reload.available_count).to eq(0)
      end
    end

    context "貸出後に在庫が閾値を下回る場合" do
      it "low_stock_alert メールをキューに積む" do
        low_equipment = create(:equipment, total_count: 3, available_count: 2, low_stock_threshold: 2)
        expect {
          service.create(
            user: member,
            equipment_id: low_equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.to have_enqueued_mail(LoanMailer, :low_stock_alert)
      end

      it "閾値が0の場合はアラートを送らない" do
        no_threshold_equipment = create(:equipment, total_count: 3, available_count: 1, low_stock_threshold: 0)
        expect {
          service.create(
            user: member,
            equipment_id: no_threshold_equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.not_to have_enqueued_mail(LoanMailer, :low_stock_alert)
      end
    end

    context "在庫がゼロの場合" do
      let(:equipment) { create(:equipment, total_count: 1, available_count: 0) }

      it "success: false を返す" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:out_of_stock)
        expect(result[:message]).to include("在庫")
      end

      it "貸出レコードは作成されない" do
        expect {
          service.create(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.not_to change(Loan, :count)
      end
    end

    context "返却予定日が不正な場合" do
      it "開始日と同日の場合は success: false を返す" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: start_date
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end

      it "開始日より前の場合は success: false を返す" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: start_date - 1
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:validation_failed)
      end
    end

    context "論理削除済みの備品に対して申請する場合" do
      before { equipment.discard }

      it "success: false を返す" do
        result = service.create(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:equipment_not_available)
      end
    end

    context "修理中・廃棄の備品の場合" do
      %i[repair disposed].each do |status|
        it "#{status} の備品は申請できない" do
          equipment.update!(status: status)
          result = service.create(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )

          expect(result[:success]).to be false
          expect(result[:error]).to eq(:equipment_not_available)
        end
      end
    end
  end

  describe "#admin_direct_entry" do
    let(:equipment) { create(:equipment, total_count: 3, available_count: 3) }
    let(:start_date) { Date.today }
    let(:expected_return_date) { Date.today + 7 }

    context "在庫がある場合" do
      it "active ステータスの貸出レコードを作成し success: true を返す" do
        result = service.admin_direct_entry(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be true
        expect(result[:loan]).to be_persisted
        expect(result[:loan].status).to eq("active")
        expect(result[:loan].user).to eq(member)
      end

      it "備品の貸出可能数が1減少する" do
        expect {
          service.admin_direct_entry(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.to change { equipment.reload.available_count }.by(-1)
      end

      it "貸出確認メールをキューに積む" do
        expect {
          service.admin_direct_entry(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.to have_enqueued_mail(LoanMailer, :loan_confirmation)
      end
    end

    context "在庫がゼロの場合" do
      let(:equipment) { create(:equipment, total_count: 1, available_count: 0) }

      it "success: false と :out_of_stock を返す" do
        result = service.admin_direct_entry(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:out_of_stock)
      end

      it "貸出レコードは作成されない" do
        expect {
          service.admin_direct_entry(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )
        }.not_to change(Loan, :count)
      end
    end

    context "論理削除済みの備品の場合" do
      before { equipment.discard }

      it "success: false と :equipment_not_available を返す" do
        result = service.admin_direct_entry(
          user: member,
          equipment_id: equipment.id,
          start_date: start_date,
          expected_return_date: expected_return_date
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:equipment_not_available)
      end
    end

    context "修理中・廃棄の備品の場合" do
      %i[repair disposed].each do |status|
        it "#{status} の備品は登録できない" do
          equipment.update!(status: status)
          result = service.admin_direct_entry(
            user: member,
            equipment_id: equipment.id,
            start_date: start_date,
            expected_return_date: expected_return_date
          )

          expect(result[:success]).to be false
          expect(result[:error]).to eq(:equipment_not_available)
        end
      end
    end
  end

  describe "#approve" do
    let(:loan) { create(:loan, status: :pending_approval) }

    it "ステータスを active に変更し success: true を返す" do
      result = service.approve(loan_id: loan.id)

      expect(result[:success]).to be true
      expect(loan.reload.status).to eq("active")
    end

    context "承認待ち以外のステータスの場合" do
      it "active のローンは承認できない" do
        loan.update!(status: :active)
        result = service.approve(loan_id: loan.id)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(:invalid_status_transition)
      end
    end
  end

  describe "#mark_overdue" do
    it "ステータスを overdue に変更する" do
      loan = create(:loan, status: :active)
      service.mark_overdue(loan: loan)

      expect(loan.reload.status).to eq("overdue")
    end
  end
end
