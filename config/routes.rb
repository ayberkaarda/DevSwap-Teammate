Rails.application.routes.draw do
  get "messages/create"
  root "dashboard#index"



  get "telemetry", to: "telemetry#show", as: :telemetry
  get "telemetry/queue_jobs", to: "telemetry#queue_jobs", as: :telemetry_queue_jobs
  get "telemetry/online_users", to: "telemetry#online_users", as: :telemetry_online_users
  get "guide", to: "guide#show", as: :guide

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout



  resource :profile, only: [ :edit, :update ]
  delete "profile/banner", to: "profiles#remove_banner", as: :remove_profile_banner
  get "/u/:id", to: "profiles#show", as: :public_profile
  get "/u/:id/followers", to: "profiles#followers", as: :public_profile_followers
  get "/u/:id/following", to: "profiles#following", as: :public_profile_following
  resources :user_skills, only: [ :create, :update, :destroy ] # Yetenek ekleme, düzenleme ve silme yolları
  resources :github_repositories, only: [ :update ] # Repo profil görünürlüğü toggle
  resources :messages, only: [ :create, :update, :destroy ] # Gerçek zamanlı mesajlaşma + düzenle/sil
  post "messages/:id/react", to: "message_reactions#toggle", as: :toggle_message_reaction
  resources :rooms, only: [ :show ], param: :slug # Sekmeli çoklu sohbet odaları
  post "rooms/dm/:user_id", to: "rooms#start_dm", as: :start_dm_room
  post "rooms/:slug/end", to: "rooms#request_end", as: :request_end_room
  post "rooms/:slug/dismiss", to: "rooms#dismiss", as: :dismiss_room # DM sekmesini per-user gizle
  resources :ratings, only: [ :create ]

  # Dashboard widget kalıcılığı (Faz 31b) — 31c Gridstack.js entegrasyonu bunları çağıracak
  patch "dashboard_widgets/reorder", to: "dashboard_widgets#reorder", as: :reorder_dashboard_widgets
  post "dashboard_widgets/reset", to: "dashboard_widgets#reset", as: :reset_dashboard_widgets
  resources :dashboard_widgets, only: [ :update ]

  # Profil widget kalıcılığı — public profil sayfası (show) Gridstack ızgarası bunları çağırır.
  patch "profile_widgets/reorder", to: "profile_widgets#reorder", as: :reorder_profile_widgets
  post "profile_widgets/reset", to: "profile_widgets#reset", as: :reset_profile_widgets
  resources :profile_widgets, only: [ :update ]
  resources :posts, only: [ :index, :show, :create ]
  get "etiket/:tag", to: "posts#by_tag", as: :tag_posts

  # Faz 32-A — Post etkilesimleri (begeni, yorum, repost, kaydetme, gonderme).
  # Ayri, net bir blok olarak eklendi (paralel agent'la kolay textual merge icin).
  post "posts/:id/like", to: "likes#toggle_post", as: :toggle_post_like
  post "comments/:id/like", to: "likes#toggle_comment", as: :toggle_comment_like
  post "comments/:id/react", to: "comment_reactions#toggle", as: :toggle_comment_reaction
  post "posts/:id/repost", to: "reposts#toggle", as: :toggle_repost
  post "posts/:id/save", to: "saved_posts#toggle", as: :toggle_save_post
  post "posts/:id/share", to: "post_shares#create", as: :share_post
  resources :comments, only: [ :create, :destroy ]
  get "posts/:id/likers", to: "likes#post_likers", as: :post_likers
  get "posts/:id/reposters", to: "reposts#post_reposters", as: :post_reposters
  get "posts/:id/share_targets", to: "post_shares#share_targets", as: :post_share_targets

  resources :notifications, only: [ :index ] do
    collection do
      post :mark_seen
    end
    member do
      patch :dismiss
      patch :claim
    end
  end

  get "terms", to: "terms#show", as: :terms
  post "terms/accept", to: "terms#accept", as: :accept_terms
  resources :bans, only: [ :create, :destroy ]
  resources :warnings, only: [ :create ]
  resources :mutes, only: [ :create, :destroy ]

  # Terminal sohbeti gercek slash komutlari (/mute, /unmute, /block, /unblock, /ban, /unban) — sunucu-etkili.
  post "chat_commands/mute", to: "chat_commands#mute", as: :mute_chat_command
  post "chat_commands/unmute", to: "chat_commands#unmute", as: :unmute_chat_command
  post "chat_commands/block", to: "chat_commands#block", as: :block_chat_command
  post "chat_commands/unblock", to: "chat_commands#unblock", as: :unblock_chat_command
  post "chat_commands/ban", to: "chat_commands#ban", as: :ban_chat_command
  post "chat_commands/unban", to: "chat_commands#unban", as: :unban_chat_command

  # Sosyal/iliski ozellikleri — engelleme, takip, feed tercihi, ayarlar sayfasi.
  get "settings", to: "settings#show", as: :settings
  post "follows", to: "follows#toggle", as: :toggle_follow
  post "blocks", to: "blocks#create", as: :blocks
  delete "blocks/:id", to: "blocks#destroy", as: :block
  post "feed_preferences", to: "feed_preferences#create", as: :feed_preferences
  delete "feed_preferences/:id", to: "feed_preferences#destroy", as: :feed_preference
  resources :escalations, only: [ :create ]
  resources :complaints, only: [ :create, :index ]
  resources :user_roles, only: [ :update ]
  namespace :admin do
    resources :users, only: [ :index ]
    resources :complaints, only: [ :index, :destroy ] do
      member do
        patch :mark_reviewed
        patch :dismiss
        patch :mark_actioned
      end
    end
    resources :widget_resets, only: [] do
      collection do
        post :reset_dashboard
        post :reset_profile
      end
    end
  end
  # Admin genel duyuru yayini (global_announcements stream'ine broadcast).
  # dismiss: herhangi bir giris yapmis kullanici kendi gorunumunden kapatabilir.
  # destroy: sadece admin, kaliciyi tamamen siler (herkesten canli kalkar).
  resources :admin_broadcasts, only: [ :create, :destroy ] do
    member do
      post :dismiss
    end
  end
  delete "posts/:id", to: "posts#destroy", as: :destroy_post

  # PWA (Progressive Web App) route'ları — manifest ve service worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
