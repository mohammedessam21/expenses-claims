module CategorySerializer
  def self.call(category)
    category.slice(:id, :name_en, :name_ar, :limit_halalas, :active)
  end
end
