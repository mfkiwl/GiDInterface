namespace eval ::ShallowWater::examples::DamBreak {
    namespace path ::ShallowWater::examples
    Kratos::AddNamespace [namespace current]
}

proc ::ShallowWater::examples::DamBreak::Init {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawGeometry
    AssignGroups
    TreeAssignation

    GiD_Process 'Redraw
    GidUtils::UpdateWindow GROUPS
    GidUtils::UpdateWindow LAYER
    GiD_Process 'Zoom Frame
}

proc ::ShallowWater::examples::DamBreak::DrawGeometry {args} {
    Kratos::ResetModel
    GiD_Layers create main_layer
    GiD_Layers edit to_use main_layer

    # Geometry creation
    ## Points ##
    set coordinates [list 0 0 0 10 0 0 10 1 0 0 1 0]
    set geom_points [list ]
    foreach {x y z} $coordinates {
        lappend geom_points [GiD_Geometry create point append main_layer $x $y $z]
    }

    ## Lines ##
    set geom_lines [list ]
    set initial [lindex $geom_points 0]
    foreach point [lrange $geom_points 1 end] {
        lappend geom_lines [GiD_Geometry create line append stline main_layer $initial $point]
        set initial $point
    }
    lappend geom_lines [GiD_Geometry create line append stline main_layer $initial [lindex $geom_points 0]]

    ## Surface ##
    GiD_Process Mescape Geometry Create NurbsSurface {*}$geom_lines escape escape
}

proc ::ShallowWater::examples::DamBreak::AssignGroups {args} {
    # Create and assign the groups
    GiD_Groups create Body
    GiD_Groups edit color Body "#26d1a8ff"
    GiD_EntitiesGroups assign Body surfaces 1

    GiD_Groups create Walls
    GiD_Groups edit color Walls "#3b3b3bff"
    GiD_EntitiesGroups assign Walls lines [list 1 3]

    GiD_Groups create Left
    GiD_Groups edit color Left "#3b3b3bff"
    GiD_EntitiesGroups assign Left lines 4

    GiD_Groups create Right
    GiD_Groups edit color Right "#3b3b3bff"
    GiD_EntitiesGroups assign Right lines 2
}

proc ::ShallowWater::examples::DamBreak::TreeAssignation {args} {

    # Parts
    set parts [spdAux::getRoute "SWParts"]
    set part_node [customlib::AddConditionGroupOnXPath $parts Body]
    set props [list Element GENERIC_ELEMENT Material Concrete]
    spdAux::SetValuesOnBaseNode $part_node $props

    # Nodal Conditions
    # set nodal_conditions [spdAux::getRoute "SWBenchmarks"]
    # set benchmark_cond "$nodal_conditions/condition\[@n='DamBreakBenchmark'\]"
    # set benchmark_node [customlib::AddConditionGroupOnXPath $thermalnodcond Body]
    # $benchmark_node setAttribute ov surface
    # set props [list value 303.15]        ### Con los valores por defecto de Kratos ya va bien
    # spdAux::SetValuesOnBaseNode $thermalnodNode $props

    # Conditions
    set boundary_conditions [spdAux::getRoute "SWConditions"]
    set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    spdAux::AddIntervalGroup Walls "Walls//Total"
    set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond "Walls//Total"]
    $flow_rate_node setAttribute ov line
    set props [list value_component_X 303.15 selector_component_Y Not Interval Total] 
    spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    # set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond Right]
    # $flow_rate_node setAttribute ov line
    # set props [list value 303.15 Interval Total]         ### que es esto?  ASIGNAR: X impuesto, Y libre
    # spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # set flow_rate_cond "$boundary_conditions/condition\[@n='ImposedFlowRate'\]"
    # set flow_rate_node [customlib::AddConditionGroupOnXPath $flow_rate_cond Left]
    # $flow_rate_node setAttribute ov line
    # set props [list value 303.15 Interval Total]         ### que es esto?  ASIGNAR: Y impuesto, X libre
    # spdAux::SetValuesOnBaseNode $flow_rate_node $props

    # Refresh
    spdAux::RequestRefresh
}
