require "rails_helper"

RSpec.describe "CSV routes", type: :routing do
  describe "EquipmentsController CSV routes" do
    it "routes GET /equipments/export_csv" do
      expect(get: "/equipments/export_csv").to route_to("equipments#export_csv")
    end

    it "routes GET /equipments/import_template" do
      expect(get: "/equipments/import_template").to route_to("equipments#import_template")
    end

    it "routes POST /equipments/import_csv" do
      expect(post: "/equipments/import_csv").to route_to("equipments#import_csv")
    end
  end

  describe "LoansController CSV routes" do
    it "routes GET /loans/export_csv" do
      expect(get: "/loans/export_csv").to route_to("loans#export_csv")
    end
  end

  describe "Admin::CategoryMajorsController CSV routes" do
    it "routes GET /admin/category_majors/export_csv" do
      expect(get: "/admin/category_majors/export_csv").to route_to("admin/category_majors#export_csv")
    end

    it "routes GET /admin/category_majors/import_template" do
      expect(get: "/admin/category_majors/import_template").to route_to("admin/category_majors#import_template")
    end

    it "routes POST /admin/category_majors/import_csv" do
      expect(post: "/admin/category_majors/import_csv").to route_to("admin/category_majors#import_csv")
    end
  end

  describe "Admin::UsersController CSV routes" do
    it "routes GET /admin/users/export_csv" do
      expect(get: "/admin/users/export_csv").to route_to("admin/users#export_csv")
    end

    it "routes GET /admin/users/import_template" do
      expect(get: "/admin/users/import_template").to route_to("admin/users#import_template")
    end

    it "routes POST /admin/users/import_csv" do
      expect(post: "/admin/users/import_csv").to route_to("admin/users#import_csv")
    end
  end

  describe "Admin::LoansController CSV routes" do
    it "routes GET /admin/loans/import_template" do
      expect(get: "/admin/loans/import_template").to route_to("admin/loans#import_template")
    end

    it "routes POST /admin/loans/import_csv" do
      expect(post: "/admin/loans/import_csv").to route_to("admin/loans#import_csv")
    end
  end

  describe "Setup routes" do
    it "routes GET /setup" do
      expect(get: "/setup").to route_to("setups#new")
    end

    it "routes POST /setup" do
      expect(post: "/setup").to route_to("setups#create")
    end
  end
end
