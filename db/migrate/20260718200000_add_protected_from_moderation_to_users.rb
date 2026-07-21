class AddProtectedFromModerationToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :protected_from_moderation, :boolean, null: false, default: false

    # Kurucu admin hesabini (Ayberk Arda) moderasyondan koru. Idempotent ve
    # yikici degil: sadece eslesme varsa update eder, yoksa sessizce gecer.
    # GitHub kimligi uzerinden de eslestirmeye calisiriz (isim degisebilir).
    say_with_time "protecting founder admin account" do
      User.reset_column_information
      User.where(name: "Ayberk Arda")
          .or(User.where(github_username: "ayberkaarda"))
          .update_all(protected_from_moderation: true)
    end
  end

  def down
    remove_column :users, :protected_from_moderation
  end
end
