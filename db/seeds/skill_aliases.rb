# Bilinen Skill Yazim Varyantlari (Idempotent Seed)
#
# Amac: SkillResolver (app/services/skill_resolver.rb) yazma anindaki
# duplicate Skill olusumunu, alias_name -> skill eslesmesine bakarak engelliyor.
# Bu seed, yaygin bilinen yazim varyantlari icin o alias haritasini onceden
# doldurur (ör. "NodeJS" yazan bir kullanici, "Node.js" kanonik Skill'ine
# yonlendirilir).
#
# SADECE find_or_create_by! kullanir, hicbir delete/destroy icermez;
# production'da guvenle tekrar tekrar calistirilabilir.

ALIASES = {
  "Node.js" => [ "NodeJS", "Node JS", "Node" ],
  "JavaScript" => [ "JS" ],
  "TypeScript" => [ "TS" ],
  "PostgreSQL" => [ "Postgres", "psql" ],
  "C++" => [ "Cpp", "C Plus Plus" ],
  "C#" => [ "CSharp", "C Sharp" ],
  ".NET" => [ "Dotnet", "DotNet" ],
  "Ruby on Rails" => [ "Rails", "RoR" ],
  "Kubernetes" => [ "K8s" ],
  "Continuous Integration" => [ "CI/CD", "CI CD" ]
}.freeze

normalize = ->(n) { n.downcase.strip.delete(" .") }

ALIASES.each do |canonical_name, variants|
  skill = Skill.find_or_create_by!(name: canonical_name)
  ([ canonical_name ] + variants).each do |variant|
    SkillAlias.find_or_create_by!(alias_name: normalize.call(variant)) { |a| a.skill = skill }
  end
end
