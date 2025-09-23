require "rails_helper"

RSpec.describe Transferencia, type: :model do
  describe "asociaciones" do
    it { should belong_to(:articulo) }
    it { should belong_to(:persona) }
  end

  describe "validaciones" do
    it { should validate_presence_of(:fecha_inicio) }
  end

  describe "requerimientos belongs_to" do
    it "es inválida sin articulo" do
      expect(build(:transferencia, articulo: nil)).not_to be_valid
    end
    it "es inválida sin persona" do
      expect(build(:transferencia, persona: nil)).not_to be_valid
    end
  end
end
