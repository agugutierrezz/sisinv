FactoryBot.define do
  factory :brand, class: "Marca" do
    nombre { Faker::Vehicle.make }
  end
end
