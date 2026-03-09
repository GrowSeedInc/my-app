# Whenever の設定ファイル
# 編集後は `whenever --update-crontab` をコンテナ内で実行してcrontabに反映する

set :output, "#{path}/log/cron.log"
set :environment, ENV.fetch("RAILS_ENV", "development")

# 毎日 00:30 に延滞チェックジョブを実行する
every :day, at: "00:30 am" do
  runner "OverdueCheckJob.perform_later"
end
