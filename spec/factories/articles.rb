FactoryBot.define do
  factory :article, class: "Articulo" do
    identificador   { "ART-#{SecureRandom.hex(3).upcase}" }
    association :modelo, factory: :model
    fecha_ingreso { Date.today }

    persona_actual { nil }

    trait :con_persona do
      association :persona_actual, factory: :person
    end
  end
end
