require "rails_helper"

RSpec.describe "データベース設定", type: :configuration do
  describe "UUID主キー設定" do
    it "ジェネレータのprimary_key_typeがuuidに設定されている" do
      generators_config = Rails.application.config.generators
      pk_type = generators_config.options[:active_record][:primary_key_type]
      expect(pk_type).to eq(:uuid)
    end
  end

  describe "pgcrypto拡張マイグレーション" do
    it "pgcrypto有効化マイグレーションファイルが存在する" do
      migration_files = Dir[Rails.root.join("db/migrate/*_enable_pgcrypto.rb")]
      expect(migration_files).not_to be_empty
    end
  end

  describe "PostgreSQL接続設定" do
    it "adapterがpostgresqlに設定されている" do
      db_config = Rails.application.config.database_configuration
      adapter = db_config.dig("test", "adapter") || db_config.dig(:test, :adapter)
      expect(adapter).to eq("postgresql")
    end
  end
end
