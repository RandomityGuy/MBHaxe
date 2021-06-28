//-----------------------------------------------------------------------------
// Torque Game Engine
//
// Copyright (c) 2001 GarageGames.Com
//-----------------------------------------------------------------------------

new MaterialProperty(DefaultMaterial) {
   friction = 1;
   restitution = 1;
   force = 0;
};


// Will need to play with these three friction values to balance game play
new MaterialProperty(NoFrictionMaterial) {
   friction = 0.01;
   restitution = 0.5;
};

new MaterialProperty(LowFrictionMaterial) {
   friction = 0.20;
   restitution = 0.5;
};

new MaterialProperty(HighFrictionMaterial) {
   friction = 1.50;
   restitution = 0.5;
};

new MaterialProperty(VeryHighFrictionMaterial) {
   friction = 2;
   restitution = 1;
};



new MaterialProperty(RubberFloorMaterial) {
   friction = 1;
   restitution = 1;
};

new MaterialProperty(IceMaterial) {
   friction = 0.05;
   restitution = 0.5;
};

new MaterialProperty(BumperMaterial) {
   friction = 0.5;
   restitution = 0;
   force = 15;
};

new MaterialProperty(ButtonMaterial) {
   friction = 1;
   restitution = 1;
};


//
addMaterialMapping( "", DefaultMaterial);

// Textures listed in BrianH texture document
addMaterialMapping( "grid_warm" ,    DefaultMaterial);
addMaterialMapping( "grid_cool" ,    DefaultMaterial);
addMaterialMapping( "grid_neutral" , DefaultMaterial);

addMaterialMapping( "stripe_cool" ,    DefaultMaterial);
addMaterialMapping( "stripe_neutral" , DefaultMaterial);
addMaterialMapping( "stripe_warm" ,    DefaultMaterial);
addMaterialMapping( "tube_cool" ,      DefaultMaterial);
addMaterialMapping( "tube_neutral" ,   DefaultMaterial);
addMaterialMapping( "tube_warm" ,      DefaultMaterial);

addMaterialMapping( "solid_cool1" ,      DefaultMaterial);
addMaterialMapping( "solid_cool2" ,      DefaultMaterial);
addMaterialMapping( "solid_neutral1" ,   DefaultMaterial);
addMaterialMapping( "solid_neutral2" ,   DefaultMaterial);
addMaterialMapping( "solid_warm1" ,      DefaultMaterial);
addMaterialMapping( "solid_warm2" ,      DefaultMaterial);

addMaterialMapping( "pattern_cool1" ,      DefaultMaterial);
addMaterialMapping( "pattern_cool2" ,      DefaultMaterial);
addMaterialMapping( "pattern_neutral1" ,   DefaultMaterial);
addMaterialMapping( "pattern_neutral2" ,   DefaultMaterial);
addMaterialMapping( "pattern_warm1" ,      DefaultMaterial);
addMaterialMapping( "pattern_warm2" ,      DefaultMaterial);

addMaterialMapping( "friction_none" ,    NoFrictionMaterial);
addMaterialMapping( "friction_low" ,     LowFrictionMaterial);
addMaterialMapping( "friction_high" ,    HighFrictionMaterial);
// used for ramps in escher level
addMaterialMapping( "friction_ramp_yellow" ,    VeryHighFrictionMaterial);

// old textures (to be removed?)
addMaterialMapping( "grid1" , RubberFloorMaterial);
addMaterialMapping( "grid2" , RubberFloorMaterial);
addMaterialMapping( "grid3" , RubberFloorMaterial);
addMaterialMapping( "grid4" , RubberFloorMaterial);

// some part textures
addMaterialMapping( "oilslick" , IceMaterial);
addMaterialMapping( "base.slick" , IceMaterial);
addMaterialMapping( "ice.slick" , IceMaterial);
addMaterialMapping( "bumper-rubber" ,    BumperMaterial);
addMaterialMapping( "triang-side" ,      BumperMaterial);
addMaterialMapping( "triang-top" ,      BumperMaterial);
addMaterialMapping( "pball-round-side" , BumperMaterial);
addMaterialMapping( "pball-round-top" , BumperMaterial);
addMaterialMapping( "pball-round-bottm" , BumperMaterial);
addMaterialMapping( "button" , ButtonMaterial);
