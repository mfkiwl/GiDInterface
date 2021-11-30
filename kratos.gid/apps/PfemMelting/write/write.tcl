namespace eval ::PfemMelting::write {
    namespace path ::PfemMelting
    Kratos::AddNamespace [namespace current]

    variable writeAttributes

}

proc ::PfemMelting::write::Init { } {
    SetAttribute parts_un [::PfemMelting::GetUniqueName parts]
    SetAttribute conditions_un [::PfemMelting::GetUniqueName conditions]
    SetAttribute materials_un [::PfemMelting::GetUniqueName materials]
    SetAttribute results_un [::PfemMelting::GetUniqueName results]
    SetAttribute time_parameters_un [::PfemMelting::GetUniqueName time_parameters]

    SetAttribute model_part_name [::PfemMelting::GetWriteProperty model_part_name]
    SetAttribute properties_location [::PfemMelting::GetWriteProperty properties_location]
    SetAttribute materials_file [::PfemMelting::GetWriteProperty materials_file]
}

# Events
proc ::PfemMelting::write::writeModelPartEvent { } {
    # Init data
    write::initWriteConfiguration [GetAttributes]

    # Headers
    write::writeModelPartData

    # Nodal coordinates (1: Print only Fluid nodes <inefficient> | 0: the whole mesh <efficient>)
    write::writeNodalCoordinates

    # Element connectivities (Groups on FLParts)
    write::writeElementConnectivities

    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    foreach group [[customlib::GetBaseRoot] selectNodes $xp1] {
        set groupid [$group @n]
        set groupid [write::GetWriteGroupName $groupid]
        set condid [[$group parent] @n]
        ::write::writeGroupSubModelPart $condid $groupid "Nodes"
    }
}

proc ::PfemMelting::write::writeCustomFilesEvent { } {
    set mats_json [dict create ]
    foreach mat [dict get [write::getPropertiesList [GetAttribute parts_un] True [GetAttribute model_part_name]] properties] {
        dict set mat model_part_name ModelPart
        dict lappend mats_json properties $mat
    }
    write::OpenFile [GetAttribute materials_file]
    write::WriteJSON $mats_json
    write::CloseFile
    write::SetConfigurationAttribute main_launch_file [::PfemMelting::GetAttribute main_launch_file]
}

# Attributes block
proc ::PfemMelting::write::GetAttribute {att} {
    variable writeAttributes
    return [dict get $writeAttributes $att]
}

proc ::PfemMelting::write::GetAttributes {} {
    variable writeAttributes
    return $writeAttributes
}

proc ::PfemMelting::write::SetAttribute {att val} {
    variable writeAttributes
    dict set writeAttributes $att $val
}
proc ::PfemMelting::write::AddAttributes {configuration} {
    variable writeAttributes
    set writeAttributes [dict merge $writeAttributes $configuration]
}
