require "rails_helper"

RSpec.describe Marca, type: :model do
  describe "asociaciones" do
    it { should have_many(:modelos) }
  end

  describe "validaciones" do
    subject { create(:brand, nombre: "Ford") }
    it { should validate_presence_of(:nombre) }
    it { should validate_uniqueness_of(:nombre).case_insensitive }
  end
end
