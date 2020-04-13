
proc ::Structural::examples::Membrane {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawMembraneGeometry
    # AssignTrussCantileverMeshSizes
    # TreeAssignationTrussCantilever
}

proc Structural::examples::DrawMembraneGeometry {args} {
    Kratos::ResetModel
    set structure_layer Structure
    GiD_Process Mescape 'Layers ChangeName Layer0 $structure_layer escape

    # Geometry creation
    GiD_Process Mescape Geometry Create Object Rectangle 0 0 0 10 10 0 escape
    GiD_Process 'Zoom Frame

    # Group creation
    GiD_Groups create Structure

    GiD_EntitiesGroups assign Structure surfaces [GiD_EntitiesLayers get $structure_layer surfaces]

    GidUtils::UpdateWindow GROUPS
}

proc Structural::examples::AssignTrussCantileverMeshSizes {args} {
    GiD_Process Mescape Meshing Structured Lines 1 {*}[GiD_EntitiesGroups get Structure lines] escape escape
}


proc Structural::examples::TreeAssignationTrussCantilever {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype point
    if {$::Model::SpatialDimension eq "3D"} { set condtype line }

    # Structural
    # gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Truss'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Structure]
    $structPartsNode setAttribute ov line
    set constLawNameStruc "TrussConstitutiveLaw"
    set props [list Element TrussElement$nd ConstitutiveLaw $constLawNameStruc CROSS_AREA 0.01 DENSITY 1500.0]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # Structural Displacement
    GiD_Groups clone XYZ Total
    GiD_Groups edit parent Total XYZ
    spdAux::AddIntervalGroup XYZ "XYZ//Total"
    GiD_Groups edit state "XYZ//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "XYZ//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Structural Displacement
    GiD_Groups clone XZ Total
    GiD_Groups edit parent Total XZ
    spdAux::AddIntervalGroup XZ "XZ//Total"
    GiD_Groups edit state "XZ//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "XZ//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y Not selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Structural Displacement
    GiD_Groups clone Z Total
    GiD_Groups edit parent Total Z
    spdAux::AddIntervalGroup Z "Z//Total"
    GiD_Groups edit state "Z//Total" hidden
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Z//Total"]
    $structDisplacementNode setAttribute ov point
    set props [list selector_component_X Not selector_component_Y Not selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Point load
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='PointLoad$nd'\]"
    GiD_Groups clone Load Total
    GiD_Groups edit parent Total Load
    spdAux::AddIntervalGroup Load "Load//Total"
    GiD_Groups edit state "Load//Total" hidden
    $structDisplacementNode setAttribute ov point
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "Load//Total"]
    set props [list ByFunction No modulus 10000 value_direction_Y -1 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Structure domain time parameters
    set chanparameterse_list [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
