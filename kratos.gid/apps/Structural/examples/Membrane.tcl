
proc ::Structural::examples::Membrane {args} {
    if {![Kratos::IsModelEmpty]} {
        set txt "We are going to draw the example geometry.\nDo you want to lose your previous work?"
        set retval [tk_messageBox -default ok -icon question -message $txt -type okcancel]
		if { $retval == "cancel" } { return }
    }
    DrawMembraneGeometry
    TreeAssignationMembrane
    AssignMembraneMeshSizes
}

proc Structural::examples::DrawMembraneGeometry {args} {
    Kratos::ResetModel
    set structure_layer Structure
    GiD_Process Mescape 'Layers ChangeName Layer0 $structure_layer escape

    # Geometry creation
    GiD_Process Mescape Geometry Create Object Rectangle 0 0 0 10 10 0 escape
    GiD_Process 'Zoom Frame

    # Group creation
    GiD_Groups create Membrane
    GiD_Groups create Edges
    GiD_Groups create XYZ
    GiD_Groups create Load

    GiD_EntitiesGroups assign Membrane surfaces [GiD_EntitiesLayers get $structure_layer surfaces]
    GiD_EntitiesGroups assign Edges lines [GiD_EntitiesLayers get $structure_layer lines]
    GiD_EntitiesGroups assign XYZ lines 1
    GiD_EntitiesGroups assign Load surfaces 1

    GidUtils::UpdateWindow GROUPS
}

proc Structural::examples::AssignMembraneMeshSizes {args} {
    # GiD_Process Mescape Meshing Structured Surfaces 1 escape 10 3 4 escape escape
}

proc Structural::examples::TreeAssignationMembrane {args} {
    set nd $::Model::SpatialDimension
    set root [customlib::GetBaseRoot]
    set elemtype surface
    # set condtype line

    # Structural
    gid_groups_conds::setAttributesF {container[@n='Structural']/container[@n='StageInfo']/value[@n='SolutionType']} {v Static}

    # Structural Parts
    set structParts [spdAux::getRoute "STParts"]/condition\[@n='Parts_Membrane'\]
    set structPartsNode [customlib::AddConditionGroupOnXPath $structParts Membrane]
    $structPartsNode setAttribute ov surface
    set constLawNameStruc "LinearElasticPlaneStress_3D"
    set props [list Element MembraneElement$nd ConstitutiveLaw $constLawNameStruc DENSITY 7850 YOUNG_MODULUS 206.9e9 POISSON_RATIO 0.29 THICKNESS 0.1]
    spdAux::SetValuesOnBaseNode $structPartsNode $props

    # GiD_Process "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']} group {n Structure}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n Element pn Element actualize_tree 1 values MembraneElement dict {[GetElements ElementType Membrane]} state normal v MembraneElement}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n ConstitutiveLaw pn {Constitutive law} actualize_tree 1 values {[GetConstitutiveLaws]} dict {[GetAllConstitutiveLaws]} state {} v LinearElasticPlaneStress_3D}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n Material pn Material editable 0 help {Choose a material from the database} update_proc CambioMat values_tree {[give_materials_list]} actualize_tree 1 state normal v Steel}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n THICKNESS pn Thickness unit_magnitude L help Thickness string_is double state {[PartParamState]} show_in_window 1 v 1.0 units m}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PRESTRESS_VECTOR pn {Membrane prestress} fieldtype vector dimensions 3 help {Membrane prestress} state {[PartParamState]} show_in_window 1 v 0,0,0}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PROJECTION_TYPE_COMBO pn {Projection type} values rotational,planar,file dict rotational,rotational,planar,planar,file,file actualize_tree 1 state {[PartParamState]} help {Projection type} show_in_window 1 v rotational}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PRESTRESS_AXIS_GLOBAL pn {Projection direction} fieldtype vector dimensions 3 help {Projection direction} state {[PartParamState]} show_in_window 1 v 0,0,0}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PRESTRESS_AXIS_1_GLOBAL pn {Projection direction 1} fieldtype vector dimensions 3 help {Projection direction 1} state {[PartParamState]} show_in_window 1 v 0,0,0}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PRESTRESS_AXIS_2_GLOBAL pn {Projection direction 2} fieldtype vector dimensions 3 help {Projection direction 2} state {[PartParamState]} show_in_window 1 v 0,0,0}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n PROJECTION_TYPE_FILEPATH pn {Projection file} values {[GetFilesValues]} update_proc AddFile help {Projection file} state {[PartParamState]} type tablefile show_in_window 1 v {- No file}}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n DENSITY pn Density unit_magnitude Density help Density string_is double state {[PartParamState]} show_in_window 1 v 7850 units kg/m^3}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n YOUNG_MODULUS pn {Young Modulus} unit_magnitude P help {Young Modulus} string_is double state {[PartParamState]} show_in_window 1 v 206.9e9 units Pa}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n POISSON_RATIO pn {Poisson Ratio} help {Poisson Ratio} string_is double state {[PartParamState]} show_in_window 1 v 0.29}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n YIELD_STRESS pn {Yield stress} unit_magnitude P help {Yield stress} string_is double state {[PartParamState]} show_in_window 1 v 5.5e6 units Pa}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n REFERENCE_HARDENING_MODULUS pn {Kinematic hardening modulus} help {Kinematic hardening modulus} string_is double state {[PartParamState]} show_in_window 1 v 1.0}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n ISOTROPIC_HARDENING_MODULUS pn {Isotropic hardening modulus} help {Isotropic hardening modulus} string_is double state {[PartParamState]} show_in_window 1 v 0.12924}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n INFINITY_HARDENING_MODULUS pn {Saturation hardening modulus} help {Saturation hardening modulus} string_is double state {[PartParamState]} show_in_window 1 v 0.0}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n HARDENING_EXPONENT pn {Hardening exponent} help {Hardening exponent} string_is double state {[PartParamState]} show_in_window 1 v 1.0}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n CROSS_AREA pn {Cross area} unit_magnitude Area help {Cross area} string_is double state {[PartParamState]} show_in_window 1 v 1.0 units m^2}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n TRUSS_PRESTRESS_PK2 pn Prestress unit_magnitude P help Prestress string_is double state {[PartParamState]} show_in_window 1 v 0.0 units Pa}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n TORSIONAL_INERTIA pn {Torsional inertia} unit_magnitude L^4 help {Torsional inertia} string_is double state {[PartParamState]} show_in_window 1 v 1.0 units m^4}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n I22 pn {Inertia 22} unit_magnitude L^4 help {Inertia 22} string_is double state {[PartParamState]} show_in_window 1 v 1.0 units m^4}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Parts']/condition[@n='Parts_Membrane']/group[@n='Structure']} value {n I33 pn {Inertia 33} unit_magnitude L^4 help {Inertia 33} string_is double state {[PartParamState]} show_in_window 1 v 1.0 units m^4}"

    # GiD_Process "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']} group {n Edges ov line}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n selector_component_X pn {Component X} values ByFunction,ByValue,Not dict {ByFunction,By function,ByValue,By value,Not,Not set} state {[ConditionParameterState]} help Component show_in_window 1 cal_state normal v ByValue}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n function_component_X pn {Function X (x,y,z,t)} help Component state hidden v 2*x}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n value_component_X wn {DISPLACEMENT _X} pn {Value X} unit_magnitude L help Component show_in_window 1 state {} v 0.0 units m}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n selector_component_Y pn {Component Y} values ByFunction,ByValue,Not dict {ByFunction,By function,ByValue,By value,Not,Not set} state {[ConditionParameterState]} help Component show_in_window 1 cal_state normal v ByValue}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n function_component_Y pn {Function Y (x,y,z,t)} help Component state hidden v 2*x}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n value_component_Y wn {DISPLACEMENT _Y} pn {Value Y} unit_magnitude L help Component show_in_window 1 state {} v 0.0 units m}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n selector_component_Z pn {Component Z} values ByFunction,ByValue,Not dict {ByFunction,By function,ByValue,By value,Not,Not set} state {[CheckDimension 3D]} help Component show_in_window 1 v ByValue}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n function_component_Z pn {Function Z (x,y,z,t)} help Component state hidden v 2*x}" "-tcl- gid_groups_conds::addF -resolve_parametric 1 {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n value_component_Z wn {DISPLACEMENT _Z} pn {Value Z} unit_magnitude L help Component state {[CheckDimension 3D]} show_in_window 1 v 0.0 units m}" "-tcl- gid_groups_conds::addF {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']/group[@n='Edges']} value {n Interval pn {Time interval} values {[getIntervals]} help Displacement state normal v Total}" "-tcl- gid_groups_conds::addF groups group {n Edges//Total onoff 1 color #ff00ff type {}}" "-tcl- gid_groups_conds::addF {container[@n='interval_groups']} interval_group {parent Edges child Edges//Total}"

    # Structural Displacement
    # # GiD_Groups clone Edges Total
    # # GiD_Groups edit parent Total Edges
    # spdAux::AddIntervalGroup Edges "Edges//Total"
    # # GiD_Groups edit state "Edges//Total" hidden
    # set structDisplacement {container[@n='Structural']/container[@n='Boundary Conditions']/condition[@n='DISPLACEMENT']}
    # set structDisplacementNode [customlib::AddConditionGroupOnXPath $structDisplacement "Edges//Total"]
    # $structDisplacementNode setAttribute ov line
    # set props [list selector_component_X ByValue value_component_X 0.0 selector_component_Y ByValue value_component_Y 0.0 selector_component_Z ByValue value_component_Z 0.0 Interval Total]
    # spdAux::SetValuesOnBaseNode $structDisplacementNode $props

    # Surface load
    GiD_Groups clone Membrane Total
    # GiD_Groups edit parent Total Membrane
    spdAux::AddIntervalGroup Membrane "Load//Total"
    # GiD_Groups edit state "Membrane//Total" hidden
    set structLoad "container\[@n='Structural'\]/container\[@n='Loads'\]/condition\[@n='SurfacePressure$nd'\]"
    set LoadNode [customlib::AddConditionGroupOnXPath $structLoad "Membrane"]
    $LoadNode setAttribute ov surface
    set props [list ByFunction No value 50 Interval Total]
    spdAux::SetValuesOnBaseNode $LoadNode $props

    # Structure domain time parameters
    set parameters [list EndTime 25.0 DeltaTime 0.1]
    set xpath [spdAux::getRoute STTimeParameters]
    spdAux::SetValuesOnBasePath $xpath $parameters

    # # Parallelism
    # set parameters [list ParallelSolutionType OpenMP OpenMPNumberOfThreads 4]
    # set xpath [spdAux::getRoute "Parallelization"]
    # spdAux::SetValuesOnBasePath $xpath $parameters

    spdAux::RequestRefresh
}
