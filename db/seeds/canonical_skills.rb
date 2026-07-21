# Kanonik Skill Havuzu (Idempotent Seed)
#
# Amaç: GithubScanJob (app/jobs/github_scan_job.rb), GitHub Linguist'in döndürdüğü
# TAM dil isimleriyle (ör. "JavaScript") otomatik olarak Skill.find_or_create_by
# çağırıyor ve bunları SADECE "teaching" tarafına yazıyor. "Learning" tarafını
# dolduran tek yol profiles/edit.html.erb'deki collection_select dropdown'u ve o
# dropdown @available_skills = Skill.all havuzundan besleniyor. Bu havuz önceden
# neredeyse boş olduğu için kullanıcılar GitHub taramasının üreteceği isimlerle
# BİREBİR aynı Skill satırlarını learning tarafında seçemiyor.
#
# Bu seed, GitHub Linguist'in gerçek dil isimleriyle birebir eşleşen popüler
# programlama dillerini ve GitHub taramasının asla yakalayamayacağı
# framework/araç/kavramları ÖNCEDEN Skill havuzuna ekleyerek bu sorunu AZALTIR
# (kökten çözmez — kanonikleştirme/alias tablosu ayrı bir backlog maddesidir).
#
# SADECE find_or_initialize_by + save! kullanır, hiçbir delete/destroy içermez;
# production'da güvenle tekrar tekrar çalıştırılabilir. find_or_create_by! ile
# farkı: bir isim ZATEN varsa bile bu seed onun `category`'sini burada tanımlı
# değere GÜNCELLER (find_or_create_by!'ın bloğu sadece CREATE anında çalışır,
# var olan bir kaydın kategorisini asla güncellemez — Faz 26'da 3 kategoriden
# (language/framework/tool) 9 kategoriye geçerken mevcut kayıtların kategorisini
# de taşımamız gerektiği için bu fark önemli).
#
# Faz 26: kategori taksonomisi 3 değerden (language/framework/tool) 9 değere
# genişletildi (Languages, Frontend Frameworks & Libraries, Backend Frameworks,
# Databases & ORMs, Cloud & DevOps, Machine Learning & Data Science,
# Game Development, OS & System Administration, Testing & Tools).
# Mevcut 95 skill isminden HİÇBİRİ kaybedilmedi/yeniden adlandırılmadı — sadece
# `category` değerleri yeni taksonomiye taşındı. Ayrıca gelistirme-prompt.md
# madde 7.2'de istenen eksik kapsam (Web3, sistem yönetimi, ek oyun motorları,
# birkaç yaygın siber güvenlik aracı) eklendi.

canonical_skills_before = Skill.count

# Faz 31 (genişletme): kullanıcı geri bildirimi "şu donanım/dil/framework yok"
# diyememeli. Her kategori, gerçek dünyada yaygın kullanılan ama havuzda eksik
# kalan teknolojilerle kabaca İKİYE KATLANDI. Mevcut hiçbir isim silinmedi/
# yeniden adlandırılmadı; yalnızca yeni satırlar eklendi (idempotent seed).
CATEGORIES = {
  # a) GitHub Linguist dil isimleriyle birebir eşleşen popüler programlama dilleri
  "language" => [
    "JavaScript",
    "TypeScript",
    "Python",
    "Ruby",
    "Java",
    "Go",
    "Rust",
    "C++",
    "C#",
    "C",
    "PHP",
    "Swift",
    "Kotlin",
    "Objective-C",
    "Dart",
    "Scala",
    "Elixir",
    "Erlang",
    "Haskell",
    "Shell",
    "PowerShell",
    "HTML",
    "CSS",
    "SCSS",
    "Vue",
    "Lua",
    "Perl",
    "R",
    "Clojure",
    "Julia",
    "Groovy",
    "Objective-C++",
    "MATLAB",
    "Assembly",
    "F#",
    "OCaml",
    "Crystal",
    "Nim",
    "Zig",
    "Haxe",
    "CoffeeScript",
    "Solidity",
    "Vim Script",
    "Emacs Lisp",
    "Fortran",
    "COBOL",
    "Ada",
    "Prolog",
    "Racket",
    "Scheme",
    # Faz 31 genişletme: ek diller
    "WebAssembly",
    "SQL",
    "PL/SQL",
    "GraphQL Schema",
    "GLSL",
    "HLSL",
    "Elm",
    "ReScript",
    "PureScript",
    "D",
    "Delphi",
    "Visual Basic .NET",
    "ABAP",
    "Apex",
    "Hack",
    "Mojo",
    "Q#",
    "Tcl",
    "Smalltalk",
    "VHDL",
    "Verilog",
    "GDScript",
    "AppleScript",
    "Batchfile",
    "Makefile"
  ],

  # b) Frontend framework/kütüphaneler
  "frontend_framework" => [
    "React",
    "Next.js",
    "Vue.js",
    "Angular",
    "Svelte",
    "SvelteKit",
    "Nuxt.js",
    "Tailwind CSS",
    "Bootstrap",
    "Flutter",
    "React Native",
    # Faz 31 genişletme: ek frontend framework/kütüphaneler
    "SolidJS",
    "Qwik",
    "Astro",
    "Remix",
    "Preact",
    "Ember.js",
    "Alpine.js",
    "Lit",
    "Stimulus",
    "Redux",
    "jQuery",
    "Sass",
    "Material UI",
    "Chakra UI",
    "shadcn/ui",
    "Ionic",
    "Gatsby",
    "Storybook",
    "Three.js",
    "Vuetify",
    "Framer Motion"
  ],

  # c) Backend framework'ler (+ Faz 26 madde 7.2: Web3/blockchain geliştirme
  #    araçları da bu kategoriye eklendi — sunucu tarafı/akıllı kontrat
  #    geliştirme ekosistemine daha yakın olduğu için)
  "backend_framework" => [
    "Ruby on Rails",
    "Django",
    "Node.js",
    "Express",
    "Spring Boot",
    "Flask",
    "FastAPI",
    "ASP.NET Core",
    "Laravel",
    "GraphQL",
    "gRPC",
    # Faz 26 madde 7.2: Web3 teknolojileri
    "Ethereum",
    "Web3.js",
    "Hardhat",
    # Faz 31 genişletme: ek backend framework/runtime
    "NestJS",
    "Fastify",
    "Koa",
    "Deno",
    "Bun",
    "Phoenix",
    "Fiber",
    "Gin",
    "Actix",
    "Symfony",
    "Sinatra",
    "Hanami",
    "Ktor",
    "Micronaut",
    "Quarkus",
    "Play Framework",
    "Django REST Framework",
    "Socket.IO",
    "Apollo GraphQL",
    "tRPC",
    # Faz 31 genişletme: ek Web3/blockchain araçları
    "Solana",
    "Truffle",
    "Foundry",
    "ethers.js"
  ],

  # d) Veritabanları & ORM'ler
  "database" => [
    "PostgreSQL",
    "Redis",
    "MySQL",
    "MongoDB",
    "Elasticsearch",
    # Faz 31 genişletme: ek veritabanları
    "SQLite",
    "MariaDB",
    "Oracle Database",
    "Microsoft SQL Server",
    "Cassandra",
    "DynamoDB",
    "CockroachDB",
    "ClickHouse",
    "Neo4j",
    "ScyllaDB",
    "Couchbase",
    "InfluxDB",
    "Snowflake",
    "Firebase",
    "Supabase",
    "Memcached",
    # Faz 31 genişletme: ORM'ler / veri erişim katmanları
    "Prisma",
    "Sequelize",
    "SQLAlchemy",
    "TypeORM",
    "Drizzle ORM"
  ],

  # e) Cloud & DevOps
  "cloud_devops" => [
    "Docker",
    "Kubernetes",
    "AWS",
    "Terraform",
    "Jenkins",
    "GitHub Actions",
    "Ansible",
    "RabbitMQ",
    # Faz 31 genişletme: ek bulut sağlayıcılar & platformlar
    "Microsoft Azure",
    "Google Cloud",
    "DigitalOcean",
    "Heroku",
    "Vercel",
    "Netlify",
    "Cloudflare",
    "OpenShift",
    # Faz 31 genişletme: ek DevOps / IaC / gözlemlenebilirlik araçları
    "Helm",
    "ArgoCD",
    "Pulumi",
    "HashiCorp Vault",
    "Consul",
    "Nomad",
    "Istio",
    "Prometheus",
    "Grafana",
    "Datadog",
    "Sentry",
    "GitLab CI",
    "CircleCI",
    "CloudFormation",
    "Vagrant",
    "Podman",
    "Apache Kafka"
  ],

  # f) Machine Learning & Veri Bilimi
  "machine_learning" => [
    "Machine Learning",
    "TensorFlow",
    "PyTorch",
    # Faz 31 genişletme: ek ML/veri bilimi kütüphane & araçları
    "Scikit-learn",
    "Keras",
    "Hugging Face",
    "LangChain",
    "LlamaIndex",
    "OpenCV",
    "Pandas",
    "NumPy",
    "Matplotlib",
    "Jupyter",
    "spaCy",
    "NLTK",
    "XGBoost",
    "Apache Spark",
    "Stable Diffusion",
    "ONNX",
    "MLflow",
    "CUDA"
  ],

  # g) Oyun Geliştirme (+ Faz 26 madde 7.2: Unreal Engine, Godot eklendi)
  "game_development" => [
    "Unity",
    "Unreal Engine",
    "Godot",
    # Faz 31 genişletme: ek oyun motorları & framework'ler
    "GameMaker",
    "Phaser",
    "Bevy",
    "MonoGame",
    "libGDX",
    "Pygame",
    "Cocos2d",
    "CryEngine",
    "RPG Maker",
    "Roblox Studio",
    "Blender"
  ],

  # h) İşletim Sistemi & Sistem Yönetimi (Faz 26 madde 7.2: tamamı yeni —
  #    önceden bu kategori hiç yoktu. Birkaç yaygın siber güvenlik aracı da
  #    (Nmap, Wireshark, Metasploit, Burp Suite) mantıksal olarak buraya
  #    eklendi.)
  "os_sysadmin" => [
    "Linux",
    "Bash",
    "systemd",
    "Ubuntu",
    "Debian",
    "Nmap",
    "Wireshark",
    "Metasploit",
    "Burp Suite",
    # Faz 31 genişletme: web sunucuları & servis katmanı
    "Nginx",
    "Apache",
    "HAProxy",
    # Faz 31 genişletme: ek dağıtımlar & işletim sistemleri
    "Arch Linux",
    "Fedora",
    "CentOS",
    "Red Hat Enterprise Linux",
    "Alpine Linux",
    "FreeBSD",
    "Windows Server",
    "macOS",
    "Kali Linux",
    # Faz 31 genişletme: ek sistem yönetimi araçları
    "Zsh",
    "tmux",
    "cron",
    "SELinux",
    "iptables",
    "VMware",
    "Proxmox"
  ],

  # i) Test & Araçlar (genel geliştirici araçları da dahil — Git)
  "testing_tools" => [
    "Webpack",
    "Vite",
    "Jest",
    "Pytest",
    "RSpec",
    "Git",
    # Faz 31 genişletme: ek test framework/araçları
    "Cypress",
    "Playwright",
    "Selenium",
    "Vitest",
    "Mocha",
    "Chai",
    "Jasmine",
    "Karma",
    "JUnit",
    "TestNG",
    "Cucumber",
    "Puppeteer",
    "Testing Library",
    "Appium",
    "Postman",
    "k6",
    "JMeter",
    # Faz 31 genişletme: build / lint / paket araçları
    "ESLint",
    "Prettier",
    "Babel",
    "Rollup",
    "esbuild",
    "npm",
    "Yarn",
    "pnpm",
    "SonarQube"
  ]
}.freeze

CATEGORIES.each do |category, skill_names|
  skill_names.each do |skill_name|
    skill = Skill.find_or_initialize_by(name: skill_name)
    skill.category = category
    skill.save!
  end
end

canonical_skills_after = Skill.count
puts "🧬 Kanonik yetenek havuzu senkronize edildi: #{canonical_skills_after - canonical_skills_before} yeni yetenek eklendi (toplam #{canonical_skills_after} yetenek)."
