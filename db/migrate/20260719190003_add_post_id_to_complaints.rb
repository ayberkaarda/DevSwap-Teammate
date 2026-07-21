class AddPostIdToComplaints < ActiveRecord::Migration[8.1]
  def change
    # Nullable: sikayetlerin cogu bir kullaniciyi hedefler (post baglami olmadan).
    # Post uc-nokta menusunden acilan sikayetler bu alanla hangi postun tetikledigini
    # admin baglami icin tasir. Post silinirse referans null'a duser (admin log yine kalir).
    add_reference :complaints, :post, null: true, foreign_key: { on_delete: :nullify }
  end
end
