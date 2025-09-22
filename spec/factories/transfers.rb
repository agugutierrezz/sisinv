FactoryBot.define do
  factory :transferencia do
    association :articulo, factory: :article
    association :persona,  factory: :person
    fecha_inicio { Date.today }
    fecha_fin    { nil }
  end
end
