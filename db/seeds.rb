require "securerandom"

# Creo un Admin
admin = User.find_or_initialize_by(email_address: "admin@example.com")
admin.password = "admin12345" if admin.new_record?
admin.role = :admin
admin.save!
admin.regenerate_api_token if admin.api_token.blank?
puts " Admin email: #{admin.email_address}"
puts " Admin API token: #{admin.api_token}"

# Creo un Usuario estándar
user = User.find_or_initialize_by(email_address: "user@example.com")
user.password = "user12345" if user.new_record?
user.role = :user
user.save!
user.regenerate_api_token if user.api_token.blank?
puts " User email: #{user.email_address}"
puts " User API token: #{user.api_token}"


# Creo 8 personas
p1 = Persona.find_or_create_by!(nombre: "Ana",   apellido: "García")
p2 = Persona.find_or_create_by!(nombre: "Bruno", apellido: "Pérez")
p3 = Persona.find_or_create_by!(nombre: "Carla", apellido: "López")
p4 = Persona.find_or_create_by!(nombre: "Juan", apellido: "Gutiérrez")
p5 = Persona.find_or_create_by!(nombre: "José", apellido: "Fernández")
p6 = Persona.find_or_create_by!(nombre: "Claudia", apellido: "Rodríguez")
p7 = Persona.find_or_create_by!(nombre: "Fernanda", apellido: "Navarro")
p8 = Persona.find_or_create_by!(nombre: "Leonardo", apellido: "Jeréz")

# Creo 4 marcas y 14 modelos
dell   = Marca.find_or_create_by!(nombre: "Dell")
lenovo = Marca.find_or_create_by!(nombre: "Lenovo")
apple  = Marca.find_or_create_by!(nombre: "Apple")
hp    = Marca.find_or_create_by!(nombre: "HP")

m_xps13_2022   = Modelo.find_or_create_by!(marca: dell,   nombre: "XPS 13",      anio: 2022)
m_lat5410_2021 = Modelo.find_or_create_by!(marca: dell,   nombre: "Latitude 5410", anio: 2021)
m_t14_2023     = Modelo.find_or_create_by!(marca: lenovo, nombre: "ThinkPad T14", anio: 2023)
m_x1c_2022     = Modelo.find_or_create_by!(marca: lenovo, nombre: "X1 Carbon",   anio: 2022)
m_mbp14_2021   = Modelo.find_or_create_by!(marca: apple,  nombre: "MacBook Pro 14", anio: 2021)
m_mba13_2022   = Modelo.find_or_create_by!(marca: apple,  nombre: "MacBook Air 13", anio: 2022)
m_mba15_2023   = Modelo.find_or_create_by!(marca: apple,  nombre: "MacBook Air 15", anio: 2023)
m_mbp16_2021   = Modelo.find_or_create_by!(marca: apple,  nombre: "MacBook Pro 16", anio: 2021)
m_macmini_2023   = Modelo.find_or_create_by!(marca: apple,  nombre: "Mac mini", anio: 2023)
m_imac24_2021   = Modelo.find_or_create_by!(marca: apple,  nombre: "iMac 24", anio: 2021)
m_eb840g9_2022   = Modelo.find_or_create_by!(marca: hp,  nombre: "EliteBook 840 G9", anio: 2022)
m_pb450g8_2021   = Modelo.find_or_create_by!(marca: hp,  nombre: "ProBook 450 G8", anio: 2021)
m_sx36014_2023   = Modelo.find_or_create_by!(marca: hp,  nombre: "Spectre x360 14", anio: 2023)
m_zbf14_2022   = Modelo.find_or_create_by!(marca: hp,  nombre: "ZBook Firefly 14", anio: 2022)

# Creo 7 artículos
a1 = Articulo.find_or_create_by!(identificador: "XPS13-001") do |a|
  a.fecha_ingreso    = Date.today - 30
  a.modelo           = m_xps13_2022
  a.persona_actual   = p1  # Ana lo porta hoy
end

a2 = Articulo.find_or_create_by!(identificador: "LAT5410-002") do |a|
  a.fecha_ingreso    = Date.today - 45
  a.modelo           = m_lat5410_2021
  a.persona_actual   = p2
end

a3 = Articulo.find_or_create_by!(identificador: "T14-003") do |a|
  a.fecha_ingreso    = Date.today - 10
  a.modelo           = m_t14_2023
  a.persona_actual   = nil
end

a4 = Articulo.find_or_create_by!(identificador: "X1C-004") do |a|
  a.fecha_ingreso    = Date.today - 20
  a.modelo           = m_x1c_2022
  a.persona_actual   = p3
end

a5 = Articulo.find_or_create_by!(identificador: "MBP14-005") do |a|
  a.fecha_ingreso    = Date.today - 5
  a.modelo           = m_mbp14_2021
  a.persona_actual   = p8
end

a6 = Articulo.find_or_create_by!(identificador: "MBA13-006") do |a|
  a.fecha_ingreso  = Date.today - 3
  a.modelo         = m_mba13_2022
  a.persona_actual = p6
end

a7 = Articulo.find_or_create_by!(identificador: "HP-ELITE-007") do |a|
  a.fecha_ingreso  = Date.today - 2
  a.modelo         = m_eb840g9_2022
  a.persona_actual = p4
end

# Deja al artículo con 'persona' como portador actual; si ya lo es, no hace nada.
def set_portador!(articulo:, persona:, descripcion: nil)
  abierta = Transferencia.find_by(articulo: articulo, fecha_fin: nil)
  return if abierta&.persona_id == persona.id

  Transferencia.transaction do
    if abierta
      abierta.update!(
        fecha_fin: Time.current,
        descripcion: [ abierta.descripcion, "(cerrada auto en seed)" ].compact.join(" ")
      )
    end
    Transferencia.create!(
      articulo: articulo,
      persona: persona,
      fecha_inicio: Time.current,
      descripcion: descripcion
    )
    articulo.update!(persona_actual: persona)
  end
end

# a1: solo una asignación inicial
set_portador!(articulo: a1, persona: p1, descripcion: "Asignación inicial") if Transferencia.where(articulo: a1).none?

# a2: queremos historial p2 -> p3 SOLO la primera vez; luego aseguramos que quede p3
if Transferencia.where(articulo: a2).none?
  set_portador!(articulo: a2, persona: p2, descripcion: "Asignación inicial")
  set_portador!(articulo: a2, persona: p3, descripcion: "Reasignado a Carla")
else
  set_portador!(articulo: a2, persona: p3)
end

# a3: queremos historial p8 -> p4 SOLO la primera vez; luego aseguramos que quede p4
if Transferencia.where(articulo: a5).none?
  set_portador!(articulo: a5, persona: p8, descripcion: "Asignación inicial")
  set_portador!(articulo: a5, persona: p4, descripcion: "Reasignado a Juan")
else
  set_portador!(articulo: a5, persona: p4)
end

# Imprimo un resumen para comprobar que todo fue creado correctamente
puts "\n== Resumen ==============================="
puts "Personas:       #{Persona.count}"         # Debe dar 8
puts "Marcas:         #{Marca.count}"           # Debe dar 4
puts "Modelos:        #{Modelo.count}"          # Debe dar 14
puts "Artículos:      #{Articulo.count}"        # Debe dar 7
puts "Transferencias: #{Transferencia.count}"   # Debe dar 5
puts "=========================================="
