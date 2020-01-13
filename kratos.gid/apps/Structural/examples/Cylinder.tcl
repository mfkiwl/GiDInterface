
proc ::Structural::examples::Cylinder {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawCylinderGeometry
    AssignCylinderMeshSizes
    AssignGroupsCylinder
    TreeAssignationCylinder
    spdAux::RequestRefresh
}

proc Structural::examples::DrawCylinderGeometry {args} {
    Kratos::ResetModel
    set structure_layer Structure
    GiD_Process Mescape 'Layers ChangeName Layer0 $structure_layer escape

    # Geometry creation
    GiD_Process 'GetPointCoord Silent FNoJoin 0 0 0 escape Mescape Geometry Create Object Cylinder 0.0 0.0 0.0 0.0 0.0 1.0 10 14 escape
    GiD_Process Mescape Geometry Delete Volume 1 escape
    GiD_Process Mescape Geometry Delete Surface 4 3 escape
    GiD_Process 'Zoom Frame 'Rotate Angle 270 0
}

proc Structural::examples::AssignCylinderMeshSizes {args} {
    GiD_Process Mescape Meshing Structured Surfaces 1 2 escape 14 1 escape 31 4 6 escape escape
}

proc Structural::examples::AssignGroupsCylinder {args} {
    GiD_Groups create Membrane_Auto1
    GiD_Groups edit color Membrane_Auto1 "#26d1a8ff"
    GiD_EntitiesGroups assign Membrane_Auto1 surfaces 1
    GiD_EntitiesGroups assign Membrane_Auto1 surfaces 2

    GiD_Groups create Displacement_Auto1
    GiD_Groups edit color Displacement_Auto1 "#e0210fff"
    GiD_EntitiesGroups assign Displacement_Auto1 lines 3
    GiD_EntitiesGroups assign Displacement_Auto1 lines 4
    GiD_EntitiesGroups assign Displacement_Auto1 lines 5
    GiD_EntitiesGroups assign Displacement_Auto1 lines 6

    GidUtils::UpdateWindow GROUPS
}


proc Structural::examples::TreeAssignationCylinder {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]

    set condtype point
    if {$::Model::SpatialDimension eq "3D"} { set condtype line }

    # Structural
    # gid_groups_conds::setAttributesF {container[@n='FSI']/container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Dynamic}

    # Structural Parts
    set structParts {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']}
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Membrane_Auto1]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStress2DLaw"
    set props [list Element PrestressedMembraneElement$nd ConstitutiveLaw $constLawNameStruc THICKNESS 1.0 DENSITY 0.0 YOUNG_MODULUS 0.0 POISSON_RATIO 0.0 PRESTRESS_VECTOR "1,1,0"]
    foreach {prop val} $props {
         set propnode [$structPartsNode selectNodes "./value\[@n = '$prop'\]"]
         if {$propnode ne "" } {
              $propnode setAttribute v $val
         } else {
            W "Warning - Couldn't find property Structure $prop"
         }
    }

    # Structural Displacement
    set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement Displacement_Auto1]
    spdAux::RequestRefresh
    spdAux::RequestRefresh
    # $structDisplacementNode setAttribute ov line
    # set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    # foreach {prop val} $props {
    #      set propnode [$structDisplacementNode selectNodes "./value\[@n = '$prop'\]"]
    #      if {$propnode ne "" } {
    #           $propnode setAttribute v $val
    #      } else {
    #         W "Warning - Couldn't find property Structure $prop"
    #      }
    # }

    spdAux::RequestRefresh
}
