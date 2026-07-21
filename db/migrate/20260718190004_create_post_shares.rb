class CreatePostShares < ActiveRecord::Migration[8.1]
  def change
    create_table :post_shares do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    # NOT: bilincli olarak unique index YOK — ayni post ayni kisiye birden fazla
    # kez gonderilebilir. Bu tablonun satirlari gizlilik-hassas (yalnizca .count
    # disa acilir, alicilar listesi HICBIR yerde listelenmez).
  end
end
