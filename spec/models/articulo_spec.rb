require "rails_helper"

RSpec.describe Articulo, type: :model do
  describe "asociaciones" do
    it { should belong_to(:modelo) }
    it { should belong_to(:persona_actual).optional }
    it { should have_many(:transferencias) }
  end

  describe "validaciones" do
    subject { create(:article, identificador: "ART-UNIQ", persona_actual: nil) }

    it { should validate_presence_of(:identificador) }
    it { should validate_uniqueness_of(:identificador) }
    it { should validate_presence_of(:fecha_ingreso) }
  end

  describe "atributos por defecto" do
    it "activo es true por defecto" do
      expect(create(:article).reload.attributes["activo"]).to eq(true)
    end
  end
end
