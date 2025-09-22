require "rails_helper"

RSpec.describe Persona, type: :model do
  subject { create(:person, identificador: "ID-UNIQ-001") }

  describe "validaciones" do
    it { should validate_presence_of(:identificador) }
    it { should validate_uniqueness_of(:identificador) }
    it { should validate_presence_of(:nombre) }
    it { should validate_presence_of(:apellido) }
  end

  describe "asociaciones" do
    it { should have_many(:transferencias) }
  end

  describe "scopes" do
    it ".activos devuelve sólo no archivados" do
      p1 = create(:person)                 # archivado: false (default)
      p2 = create(:person, archivado: true)
      expect(Persona.activos).to match_array([ p1 ])
    end
  end

  describe "restricciones de borrado" do
    it "no permite borrar si tiene transferencias (restrict_with_error)" do
      p = create(:person)
      art = create(:article, persona_actual: p)
      create(:transferencia, articulo: art, persona: p, fecha_inicio: Date.today, fecha_fin: nil)

      expect { p.destroy }.not_to change(Persona, :count)
      expect(p.errors).not_to be_empty
    end
  end
end
