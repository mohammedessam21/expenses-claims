module Halalas
  def self.to_sar(halalas)
    format("%d.%02d", halalas / 100, halalas % 100)
  end
end
