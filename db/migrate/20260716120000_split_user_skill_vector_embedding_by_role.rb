class SplitUserSkillVectorEmbeddingByRole < ActiveRecord::Migration[8.1]
  def change
    add_column :user_skill_vectors, :embedding_teach, :vector, limit: 512
    add_column :user_skill_vectors, :embedding_learn, :vector, limit: 512

    add_index :user_skill_vectors, :embedding_teach,
      using: :hnsw, opclass: :vector_cosine_ops,
      name: "index_user_skill_vectors_on_embedding_teach_hnsw"
    add_index :user_skill_vectors, :embedding_learn,
      using: :hnsw, opclass: :vector_cosine_ops,
      name: "index_user_skill_vectors_on_embedding_learn_hnsw"

    remove_index :user_skill_vectors, name: "index_user_skill_vectors_on_embedding_hnsw"
    remove_column :user_skill_vectors, :embedding, :vector, limit: 512
  end
end
