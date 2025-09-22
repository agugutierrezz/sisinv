FactoryBot.define do
  factory :model, class: "Modelo" do
    association :marca, factory: :brand
    nombre { Faker::Vehicle.model }
    anio   { [ 2019, 2020, 2022, 2024 ].sample }
  end
end
