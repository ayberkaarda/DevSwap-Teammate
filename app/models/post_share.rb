class PostShare < ApplicationRecord
  belongs_to :user       # gonderen
  belongs_to :post
  belongs_to :recipient, class_name: "User"

  # GIZLILIK: bu modelin satirlari (kimin kime gonderdigi) HICBIR controller/view
  # tarafindan listelenmez — yalnizca PostShare.where(post: ...).count disa acilir.
end
