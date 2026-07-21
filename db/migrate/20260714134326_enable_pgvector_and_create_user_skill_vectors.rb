class EnablePgvectorAndCreateUserSkillVectors < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector" unless extension_enabled?("vector")

    create_table :user_skill_vectors do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.vector :embedding, limit: 512
      t.datetime :generated_at

      t.timestamps
    end

    add_index :user_skill_vectors, :embedding,
      using: :hnsw, opclass: :vector_cosine_ops,
      name: "index_user_skill_vectors_on_embedding_hnsw"
  end
end
