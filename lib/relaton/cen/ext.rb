module Relaton
  module Cen
    class Ext < Lutaml::Model::Serializable
      attribute :schema_version, :string

      xml do
        map_attribute "schema-version", to: :schema_version
      end
    end
  end
end
