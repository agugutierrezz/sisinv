require "rails_helper"

RSpec.describe Modelo, type: :model do
  describe "asociaciones" do
    it { should belong_to(:marca) }
  end

  describe "validaciones" do
    subject { build(:model, marca: create(:brand), nombre: "Focus", anio: 2020) }
    it { should validate_presence_of(:nombre) }
  end
end
