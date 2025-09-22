FactoryBot.define do
  factory :person, class: "Persona" do
    identificador { Faker::Number.unique.number(digits: 8) }
    nombre  { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
  end
end
