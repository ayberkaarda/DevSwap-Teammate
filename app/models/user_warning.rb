# NOT: Model adı bilinçli olarak "UserWarning" — Ruby'nin çekirdek `Warning`
# modülü (Warning.warn) ile çakışmayı önlemek için. Tablo adı "warnings" olarak
# korunuyor, migration/route/tablo isimleri değişmedi.
class UserWarning < ApplicationRecord
  self.table_name = "warnings"

  belongs_to :user
  belongs_to :issued_by, class_name: "User"

  validates :reason, presence: true
end
