require "rails_helper"

RSpec.describe "Equipments", type: :request do
  let!(:admin) { create(:user, :admin) }
  let(:member) { create(:user) }
  let!(:equipment) { create(:equipment) }

  describe "GET /equipments" do
    context "認証済みユーザーの場合" do
      before { sign_in member }

      it "200を返す" do
        get equipments_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "未認証の場合" do
      it "ログイン画面にリダイレクト" do
        get equipments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /equipments/:id" do
    before { sign_in member }

    it "200を返す" do
      get equipment_path(equipment)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /equipments/new" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get new_equipment_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get new_equipment_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /equipments" do
    let(:valid_params) do
      { equipment: { name: "新備品", management_number: "EQ-NEW", total_count: 3, description: "説明" } }
    end

    context "管理者の場合" do
      before { sign_in admin }

      it "備品を作成して詳細にリダイレクト" do
        expect {
          post equipments_path, params: valid_params
        }.to change(Equipment, :count).by(1)

        created = Equipment.find_by!(management_number: "EQ-NEW")
        expect(response).to redirect_to(equipment_path(created))
      end

      it "バリデーションエラー時は422を返す" do
        post equipments_path, params: { equipment: { name: "", management_number: "", total_count: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        post equipments_path, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /equipments/:id/edit" do
    context "管理者の場合" do
      before { sign_in admin }

      it "200を返す" do
        get edit_equipment_path(equipment)
        expect(response).to have_http_status(:ok)
      end

      context "備品に小分類カテゴリが設定されている場合" do
        let!(:major)  { create(:category) }
        let!(:medium) { create(:category, :medium, parent: major) }
        let!(:minor)  { create(:category, :minor, parent: medium) }
        let!(:eq_with_cat) { create(:equipment, category: minor) }

        it "@category_minor/@category_medium/@category_majorが設定される" do
          get edit_equipment_path(eq_with_cat)
          expect(response).to have_http_status(:ok)
          expect(controller.instance_variable_get(:@category_minor)).to eq(minor)
          expect(controller.instance_variable_get(:@category_medium)).to eq(medium)
          expect(controller.instance_variable_get(:@category_major)).to eq(major)
        end
      end

      context "備品にカテゴリが設定されていない場合" do
        it "@category_minor/@category_medium/@category_majorがnilになる" do
          get edit_equipment_path(equipment)
          expect(controller.instance_variable_get(:@category_minor)).to be_nil
          expect(controller.instance_variable_get(:@category_medium)).to be_nil
          expect(controller.instance_variable_get(:@category_major)).to be_nil
        end
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        get edit_equipment_path(equipment)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /equipments/:id" do
    context "管理者の場合" do
      before { sign_in admin }

      it "備品を更新して詳細にリダイレクト" do
        patch equipment_path(equipment), params: { equipment: { name: "更新後の備品名" } }
        expect(response).to redirect_to(equipment_path(equipment))
        expect(equipment.reload.name).to eq("更新後の備品名")
      end

      it "バリデーションエラー時は422を返す" do
        patch equipment_path(equipment), params: { equipment: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        patch equipment_path(equipment), params: { equipment: { name: "変更" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /equipments/:id" do
    context "管理者の場合" do
      before { sign_in admin }

      it "貸出中でない備品を論理削除して一覧にリダイレクト" do
        delete equipment_path(equipment)
        expect(response).to redirect_to(equipments_path)
        expect(equipment.reload.discarded?).to be true
      end

      it "貸出中の備品は削除できない" do
        create(:loan, equipment: equipment, status: :active)
        delete equipment_path(equipment)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(equipment.reload.discarded?).to be false
      end
    end

    context "一般ユーザーの場合" do
      before { sign_in member }

      it "403を返す" do
        delete equipment_path(equipment)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
