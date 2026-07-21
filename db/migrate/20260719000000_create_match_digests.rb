class CreateMatchDigests < ActiveRecord::Migration[8.1]
  def change
    create_table :match_digests do |t|
      t.references :user, null: false, foreign_key: true, index: false

      # Haftalik digest icin secilen en iyi eslesmelerin user id listesi.
      # Postgres jsonb: dogrudan Ruby Array olarak okunur/yazilir (serialize gerekmez).
      t.jsonb :matched_user_ids, null: false, default: []

      # Kullanici digest'i goruntuledi mi? nil ise henuz gorulmedi.
      t.datetime :seen_at

      t.timestamps
    end

    add_index :match_digests, :user_id
  end
end
