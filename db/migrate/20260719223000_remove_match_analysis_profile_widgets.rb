# Emekli edilen "match_analysis" profil widget'ının mevcut DB satırlarını temizler.
# WIDGET_TYPES'tan çıkarıldığı ve partial'ı silindiği için bu satırların render
# edilmesi sayfayı patlatırdı; view tarafında da filtrelenir ama artık geçersiz
# olan bu kayıtları kalıcı olarak kaldırmak temizdir. Yalnızca-veri migration.
class RemoveMatchAnalysisProfileWidgets < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      DELETE FROM profile_widgets WHERE widget_type = 'match_analysis'
    SQL
  end

  def down
    # Geri alınamaz: silinen özelleştirilmiş yerleşim satırları yeniden üretilemez.
    # Kullanıcılar "Varsayılana Dön" ile güncel varsayılan seti alabilir.
  end
end
