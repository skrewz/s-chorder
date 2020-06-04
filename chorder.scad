/*****************************************************************************/
/* Likely calibration properties                                             */
/*****************************************************************************/

// finger_measurements
//
// For the below, the "first joint" (joint 0) is the one at the base of the
// finger. Most people thus have joints 0, 1 and 2 on their four fingers, and
// joints 0 and 1 on their thumb (I'm not exception).
//
// The "first segment" (segment 0) thus is between joint 0 and joint 1, etc,
// until segment 2, which ends at the tip of the finger (segment 1 in the case
// of a thumb).
//
// Generally, these are measured when joints are bent 90 degrees.
//
// E.g. to measure segment 0 on pinky, you'd clench your fist and look at it
// from below. That way, joint0 and joint1 on pinky will be at an angle of at
// least 90 degrees. Then you put a caliper on those two pinky joints.
// 
// (It gets more finger-yoga-like to do this with other joints. You'll probably
// have to use another hand to hold the joint in a slightly overstretched
// position. Or take a guess.)
pinky_segment_lengths  = [ 53,  32, 28 ];
ring_segment_lengths   = [ 65,  40, 33 ];
middle_segment_lengths = [ 69,  44, 31 ];
index_segment_lengths  = [ 65,  39, 31 ];
thumb_segment_lengths  = [ 54,  40 ];

// Radii of each finger:
pinky_radius  =  7.5;
ring_radius   =  9.0;
middle_radius = 10.0;
index_radius  = 10.0;
thumb_radius  = 13.0;

// Angles at joint 0, joint 1 and joint 2, for a "comfortably glove-shaped" hand:
pinky_angles  = [20,40,20];
ring_angles   = [20,60,15];
middle_angles = [15,60,10];
index_angles  = [20,30,10];
thumb_angles  = [0,30];

// Almost-guesstimate: for a fingers-stretched hand, where are the joint 0's?
//
pinky_joint0_offset  = [ 128, -25,-20];
ring_joint0_offset   = [  96, -10,-10];
middle_joint0_offset = [  64,   0,  0];
index_joint0_offset  = [  32,  -2,  0];
thumb_joint0_offset  = [   0, -40,-50];

wristaxis_thumbside_offset  = [  32, -120,-25];
wristaxis_pinkyside_offset  = [ 112, -120,-25];
wristaxis_radius = 20;

pinky_joint0_rotation  =  12;
ring_joint0_rotation   =   0;
middle_joint0_rotation =  -3;
index_joint0_rotation  = -10;
thumb_joint0_rotation  = -90;

// MCU related measurements:


// TODO: total guesswork:
// (Clearance in the height dimension has to be fairly generous if you're using
// Dupont cables.)
mcu_clearance_wdh = [25,45,30];
mcu_wall_w = 1.5;

/*****************************************************************************/
/* Less-likely calibration properties                                        */
/*****************************************************************************/



// real m3 radius:
m3_radius = 1.5;
m3_head_radius = 3; // from memory
m3_head_clear_radius = 3.2; // from memory
m3_head_height = 2; // from memory
// so that an m3 bolt can be passed through without too much effort:
m3_clear_radius = 1.8;

// 0.3mm wire diameter 10 mm high 6mm outer diameter springs:
// https://www.aliexpress.com/item/33050149067.html
spring_radius = 3;
spring_height = 10;

// how much depression of spring before electrical contact is made:
contact_clearance = 1;

// how far down (perspective of joint1 on the thumb) the connection point is placed:
thumb_connection_point_translation_distance = 2*thumb_radius;

// the girth of the riggers that make up the most of the finger mounts
frame_radius = 5;

// Derive coordinates and rotation vectors:

// Helper functions {{{

// These helper functions calculate the coordinate following a segment, as if
// *_joint0_rotation didn't exist (it can be compensated for, later on).
function x_coord_for(startvec,angle,segment,radius) =
  startvec[0] ; // always same, given no _joint0 rotation.
function y_coord_for(startvec,angle,segment,radius) =
  startvec[1] + cos(angle)*(segment-2*radius);
function z_coord_for(startvec,angle,segment,radius) =
  startvec[2] + sin(-angle)*(segment-2*radius);

function sum(list,i=0) = i<len(list)-1 ? list[i] + sum(list,i+1) : list[i];
assert(sum([ 4, 5, 3]) == 12);
assert(sum([ 4, 1, -1]) == 4);

function rotate_coord(coord,joint0_rotation,relative_to_joint0_offset) =
  [
    // have hypotenuse and angle, want opposite:
    relative_to_joint0_offset[0]-sin(joint0_rotation)*(relative_to_joint0_offset[2]-coord[2]),
    coord[1], // remains the same when rotating around y axis
    // have hypotenuse and angle, want adjacent:
    relative_to_joint0_offset[2]-cos(joint0_rotation)*(relative_to_joint0_offset[2]-coord[2])
  ];

function coord_for(startvec,angle,segment,radius) =
  [
    x_coord_for(startvec,angle,segment,radius),
    y_coord_for(startvec,angle,segment,radius),
    z_coord_for(startvec,angle,segment,radius)
  ];

function rotation_for_euler_rotations(a) =
    [[cos(a[2]),-sin(a[2]),0],[sin(a[2]),cos(a[2]),0],[0,0,1]]
    * [[cos(a[1]),0,sin(a[1])],[0,1,0],[-sin(a[1]),0,cos(a[1])]]
    * [[1,0,0],[0,cos(a[0]),-sin(a[0])],[0,sin(a[0]),cos(a[0])]];

// }}}

// Assign {pinky,ring,middle,index,thumb}_{coords,rotation} {{{

// For pinky {{{
_pinky_coord_1 = coord_for(pinky_joint0_offset,sum([for (i=[0:0]) pinky_angles[i]]),pinky_segment_lengths[0],pinky_radius);
_pinky_coord_2 = coord_for(_pinky_coord_1,     sum([for (i=[0:1]) pinky_angles[i]]),pinky_segment_lengths[1],pinky_radius);
_pinky_coord_3 = coord_for(_pinky_coord_2,     sum([for (i=[0:2]) pinky_angles[i]]),pinky_segment_lengths[2],pinky_radius);

pinky_coords = [
  rotate_coord(pinky_joint0_offset,pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_1,     pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_2,     pinky_joint0_rotation,pinky_joint0_offset),
  rotate_coord(_pinky_coord_3,     pinky_joint0_rotation,pinky_joint0_offset)
];
pinky_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) pinky_angles[j] ? -pinky_angles[j] : 0]),
    pinky_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For ring {{{
_ring_coord_1 = coord_for(ring_joint0_offset,sum([for (i=[0:0]) ring_angles[i]]),ring_segment_lengths[0],ring_radius);
_ring_coord_2 = coord_for(_ring_coord_1,     sum([for (i=[0:1]) ring_angles[i]]),ring_segment_lengths[1],ring_radius);
_ring_coord_3 = coord_for(_ring_coord_2,     sum([for (i=[0:2]) ring_angles[i]]),ring_segment_lengths[2],ring_radius);

ring_coords = [
  rotate_coord(ring_joint0_offset,ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_1,     ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_2,     ring_joint0_rotation,ring_joint0_offset),
  rotate_coord(_ring_coord_3,     ring_joint0_rotation,ring_joint0_offset)
];
ring_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) ring_angles[j] ? -ring_angles[j] : 0]),
    ring_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For middle {{{
_middle_coord_1 = coord_for(middle_joint0_offset,sum([for (i=[0:0]) middle_angles[i]]),middle_segment_lengths[0],middle_radius);
_middle_coord_2 = coord_for(_middle_coord_1,     sum([for (i=[0:1]) middle_angles[i]]),middle_segment_lengths[1],middle_radius);
_middle_coord_3 = coord_for(_middle_coord_2,     sum([for (i=[0:2]) middle_angles[i]]),middle_segment_lengths[2],middle_radius);

middle_coords = [
  rotate_coord(middle_joint0_offset,middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_1,     middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_2,     middle_joint0_rotation,middle_joint0_offset),
  rotate_coord(_middle_coord_3,     middle_joint0_rotation,middle_joint0_offset)
];
middle_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) middle_angles[j] ? -middle_angles[j] : 0]),
    middle_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For index {{{
_index_coord_1 = coord_for(index_joint0_offset,sum([for (i=[0:0]) index_angles[i]]),index_segment_lengths[0],index_radius);
_index_coord_2 = coord_for(_index_coord_1,     sum([for (i=[0:1]) index_angles[i]]),index_segment_lengths[1],index_radius);
_index_coord_3 = coord_for(_index_coord_2,     sum([for (i=[0:2]) index_angles[i]]),index_segment_lengths[2],index_radius);

index_coords = [
  rotate_coord(index_joint0_offset,index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_1,     index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_2,     index_joint0_rotation,index_joint0_offset),
  rotate_coord(_index_coord_3,     index_joint0_rotation,index_joint0_offset)
];
index_rotation = [ for (i=[0:3])
  [
    sum([for (j=[0:i]) index_angles[j] ? -index_angles[j] : 0]),
    index_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// For thumb {{{
// FIXME/HACK: Using 0.5 thumb_radius to compensate for the geometry of the
// ball of the thumb.
_thumb_coord_1 = coord_for(thumb_joint0_offset,sum([for (i=[0:0]) thumb_angles[i]]),thumb_segment_lengths[0],0.5*thumb_radius);
_thumb_coord_2 = coord_for(_thumb_coord_1,     sum([for (i=[0:1]) thumb_angles[i]]),thumb_segment_lengths[1],thumb_radius);

thumb_coords = [
  rotate_coord(thumb_joint0_offset,thumb_joint0_rotation,thumb_joint0_offset),
  rotate_coord(_thumb_coord_1,     thumb_joint0_rotation,thumb_joint0_offset),
  rotate_coord(_thumb_coord_2,     thumb_joint0_rotation,thumb_joint0_offset),
];
thumb_rotation = [ for (i=[0:2])
  [
    // Ternary expression necessary to handle that there is no angle available
    // at joint2 for a thumb:
    sum([for (j=[0:i]) thumb_angles[j] ? -thumb_angles[j] : 0]),
    thumb_joint0_rotation,
    0, // always 0 when rotating in y and x axes
  ],
];

// }}}

// }}}

// Calculating where the thumb connection point is {{{
thumb_connection_point = 
thumb_coords[1]+
  -thumb_connection_point_translation_distance*rotation_for_euler_rotations(thumb_rotation[1])*[0,0,1];
// }}}

// Calculating where the finger-end attaches to the body {{{
// Warning: inexact science at play. Technically, these points could be derived
// from observed angles between e.g. index and middle joint0's.

finger_end_connection_point_thumb = 
  0.2*index_joint0_offset+
  0.8*thumb_connection_point+
  [0,-frame_radius,0];

finger_end_connection_point_index = 
  0.6*index_joint0_offset + 
  0.4*middle_joint0_offset+
  [0,-8,-10-frame_radius];

finger_end_connection_point_pinky = 
  0.3*ring_joint0_offset + 
  0.7*pinky_joint0_offset+
  [0,-8,-8-frame_radius];

finger_end_connection_point_radius = frame_radius;

// }}}

// Helper modules:

module cylinder_from_to (origin,dest,radius1,radius2)
{ // {{{
  length = sqrt(
    pow(origin[0]-dest[0],2)+
    pow(origin[1]-dest[1],2)+
    pow(origin[2]-dest[2],2)
  );

  rotation_upwards = atan((dest[2]-origin[2])/sqrt(pow(dest[0]-origin[0],2)+pow(dest[1]-origin[1],2)));

  tangent = (dest[1]-origin[1])/(dest[0]-origin[0]);
  rotation_in_plane = atan(tangent) + (0 > (dest[0]-origin[0]) ? 180 : 0);
  //echo("rot_plane=",rotation_in_plane,"rot_upwards=",rotation_upwards,"len=",length,"tan=",tangent);
  translate(origin)
    rotate([0,0,rotation_in_plane])
    rotate([0,-rotation_upwards,0])
    rotate([0,90,0])
      cylinder(r1=radius1,r2=radius2,h=length);
} // }}}

module connector_positive()
{ // {{{
  rotate([-90,0,0])
  {
    translate([0,0,0])
      cylinder(r=finger_end_connection_point_radius,h=frame_radius,$fn=20);
  }

} // }}}

module connector_negative(extra_cutout=false)
{ // {{{
  rotate([-90,0,0])
  {
    translate([0,0,-10])
      cylinder(r=m3_clear_radius,h=20,$fn=20);
    translate([0,0,2*frame_radius-m3_head_height])
      cylinder(r=m3_head_clear_radius,h=m3_head_height+30,$fn=20);
    if(extra_cutout)
      translate([0,0,5])
        cylinder(r=m3_head_clear_radius,h=10,$fn=20);
  }
} // }}}

module showcase_rotation_for_euler_rotations()
{ // {{{
 
  angles = [[119,-133,-94], [-129,112,-142], [104,-44,-139], [70,99,-85],
  [-146,171,64], [113,55,-26], [-39,-169,-58], [-8,82,39], [86,-110,-33],
  [168,119,67], [-9,58,114], [69,110,39], [99,26,175], [140,-84,95],
  [-132,-58,78], [112,-125,-47], [-94,8,-35], [20,173,-141], [-121,79,-71],
  [19,59,-131]];
              
             
  for(angle=angles)
  {           
    amplitude = 10;
    dest = amplitude*rotation_for_euler_rotations(angle)*[0,0,1];
              
    translate(dest)
      color("green")
        {      
          translate([0,0,0.2*amplitude])
            cylinder(r=0.1,h=0.8*amplitude,$fn=10);
          cylinder(r1=0.01,r2=0.4,h=0.2*amplitude,$fn=10);
        }       
                
    rotate(angle)
      color("blue")                                                       
      {                                                                  
        cylinder(r=0.1,h=0.8*amplitude,$fn=10);                         
        translate([0,0,0.8*amplitude])
          cylinder(r1=0.4,r2=0.01,h=0.2*amplitude,$fn=10);
      }                                                
  }
} // }}}

module segment (length,radius)
{ // {{{
  sphere(radius);
  cylinder(r=radius,h=length);
} // }}}

module final_segment (length,radius)
{ // {{{
  sphere(radius);
  intersection()
  {
    rotate([10,0,0])
      cylinder(r=radius,h=length);
    cylinder(r=radius,h=length);
  }

} // }}}

module contact_negative ()
{ // {{{
  translate([0,0,-8])
  {
    cylinder(r=spring_radius+0.4,h=15,$fn=20);
  }
  translate([0,0,-11])
  {
    cylinder(r=m3_clear_radius,h=15,$fn=20);
  }

  translate([0,0,-20])
  {
    cylinder(r=m3_head_radius,h=10,$fn=20);
  }
} // }}}

module contact_positive ()
{ // {{{
  %
  translate([0,0,-8])
  {
    color("silver")
    difference()
    {
      cylinder(r=spring_radius,h=spring_height,$fn=30);
      translate([0,0,-0.02])
        cylinder(r=spring_radius-0.3,h=2*spring_height,$fn=30);
    }
    translate([0,0,-6])
    {
      color("#222222")
      // FIXME: calculate this from contact_clearance:
      cylinder(r=m3_radius,h=15,$fn=30);

      color("#222222")
      cylinder(r=m3_head_radius,h=m3_head_radius,$fn=30);
    }
  }
} // }}}

// Main modules below

// A test object that can be used to establish certain calibration parameters.
module test_object ()
{ // {{{
  union ()
  {
    translate([20,20,10])
    {
      contact_positive();
    }
    difference()
    {
      cube([40,40,10]);
      translate([20,20,10])
      {
        contact_negative();
      }
    }
  }
} // }}}

// A model of the hand, as parameterised:
module hand_model ()
{ // {{{
  measurements = [
    [
      index_angles,
      index_segment_lengths,
      index_radius,
      index_joint0_offset,
      index_joint0_rotation
    ], [
      middle_angles,
      middle_segment_lengths,
      middle_radius,
      middle_joint0_offset,
      middle_joint0_rotation
    ], [
      ring_angles,
      ring_segment_lengths,
      ring_radius,
      ring_joint0_offset,
      ring_joint0_rotation
    ], [
      pinky_angles,
      pinky_segment_lengths,
      pinky_radius,
      pinky_joint0_offset,
      pinky_joint0_rotation
    ],
  ];

  for (finger_i = [0:3])
  {
    angles =          measurements[finger_i][0];
    segment_lengths = measurements[finger_i][1];
    radius =          measurements[finger_i][2];
    joint0_offset =   measurements[finger_i][3];
    joint0_rotation = measurements[finger_i][4];

    translate(joint0_offset)
    {
      rotate([0,joint0_rotation,0])
      {
        rotate([-angles[0]-90,0,0])
        {
          segment(segment_lengths[0]-2*radius,radius);
          translate([0,0,segment_lengths[0]-2*radius])
            rotate([-angles[1],0,0])
            {
              segment(segment_lengths[1]-2*radius,radius);
              translate([0,0,segment_lengths[1]-2*radius])
                rotate([-angles[2],0,0])
                {
                  final_segment(segment_lengths[2]-1*radius,radius);
                }
            }
        }
      }
    }
  }

  translate(thumb_joint0_offset)
  {
    rotate([0,thumb_joint0_rotation,0])
    {
      rotate([-thumb_joint0_offset[0]-90,0,0])
      {
        segment(thumb_segment_lengths[0]-thumb_radius,thumb_radius);
        translate([0,0,thumb_segment_lengths[0]-thumb_radius])
          rotate([-thumb_angles[1],0,0])
            final_segment(thumb_segment_lengths[1],thumb_radius);
      }
    }
  }

  cylinder_from_to(index_joint0_offset,middle_joint0_offset,index_radius,middle_radius,$fn=40);
  cylinder_from_to(middle_joint0_offset,ring_joint0_offset,middle_radius,ring_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,pinky_joint0_offset,ring_radius,pinky_radius,$fn=40);

  cylinder_from_to(thumb_joint0_offset,wristaxis_thumbside_offset,thumb_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(pinky_joint0_offset,wristaxis_pinkyside_offset,pinky_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(ring_joint0_offset,wristaxis_pinkyside_offset,ring_radius,wristaxis_radius,$fn=40);
  cylinder_from_to(index_joint0_offset,wristaxis_thumbside_offset,index_radius,wristaxis_radius,$fn=40);

  cylinder_from_to(wristaxis_thumbside_offset,wristaxis_pinkyside_offset,wristaxis_radius,wristaxis_radius,$fn=40);

  translate(wristaxis_thumbside_offset)
    sphere(r=wristaxis_radius,$fn=40);
  translate(wristaxis_pinkyside_offset)
    sphere(r=wristaxis_radius,$fn=40);

} // }}}

module finger_end()
{ // {{{

  for (connectionpoint=[
    thumb_connection_point,
    index_joint0_offset+[0,0,-index_radius-frame_radius],
    middle_joint0_offset+[0,0,-middle_radius-frame_radius],
    ring_joint0_offset+[0,0,-ring_radius-frame_radius],
    pinky_joint0_offset+[0,0,-pinky_radius-frame_radius]])
    {
      translate(connectionpoint)
      {
        sphere(r=frame_radius,$fn=30);
      }
    }


  difference()
  {
    union ()
    {
      // From index to thumb:
      cylinder_from_to(
        thumb_connection_point,
        index_joint0_offset+[0,0,-index_radius-frame_radius],
        frame_radius,frame_radius,
        $fn=30);
      // Front under-knuckles attachments:
      cylinder_from_to(
        index_joint0_offset+[0,0,-index_radius-frame_radius],
        middle_joint0_offset+[0,0,-middle_radius-frame_radius],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        middle_joint0_offset+[0,0,-middle_radius-frame_radius],
        ring_joint0_offset+[0,0,-ring_radius-frame_radius],
        frame_radius, frame_radius,$fn=30);
      cylinder_from_to(
        ring_joint0_offset+[0,0,-ring_radius-frame_radius],
        pinky_joint0_offset+[0,0,-pinky_radius-frame_radius],
        frame_radius,frame_radius,$fn=30);

      translate(finger_end_connection_point_thumb)
        connector_positive();
      translate(finger_end_connection_point_index)
        connector_positive();
      translate(finger_end_connection_point_pinky)
        connector_positive();
    }
    union()
    {
      translate(finger_end_connection_point_thumb)
        connector_negative();
      translate(finger_end_connection_point_index)
        connector_negative();
      translate(finger_end_connection_point_pinky)
        connector_negative();
    }
  }



  module contact_outrigger (joint0_offset,radius,coords,rotations)
  { // {{{
    difference()
    {
      union()
      {
        cylinder_from_to(
          joint0_offset+[0,0,-radius-frame_radius],
          coords[3]+[0,-10,0],
          frame_radius,radius,$fn=40);

          translate(coords[3])
            rotate(rotations[3])
            rotate([90,0,0])
            translate([0,-radius,-10])
            {
              cylinder(r=radius,h=2*radius);
              sphere(r=radius);
            }

        translate(coords[3])
          rotate(rotations[3])
          translate([0,0,-10])
          {
            contact_positive();
          }

      }

      translate(coords[3])
        rotate(rotations[3])
        translate([0,0,-10])
        {
          contact_negative();
        }

      translate(coords[2])
        rotate(rotations[1])
        rotate([90,0,0])
        translate([0,-4,-10-radius])
          cylinder(r=radius,h=60);
      translate(coords[3])
        rotate(rotations[3])
        rotate([90,0,0])
        translate([0,-4,-10-radius])
          cylinder(r=radius,h=60);
    }
  } // }}}
 
  contact_outrigger(pinky_joint0_offset,pinky_radius,pinky_coords,pinky_rotation);
  contact_outrigger(ring_joint0_offset,ring_radius,ring_coords,ring_rotation);
  contact_outrigger(middle_joint0_offset,middle_radius,middle_coords,middle_rotation);
  contact_outrigger(index_joint0_offset,index_radius,index_coords,index_rotation);

  module thumb_contact ()
  { // {{{
    depth=10;
    difference()
    {
      union ()
      {
        // longer outrigger
        difference()
        {
          translate(thumb_coords[1])
            rotate(thumb_rotation[1])
            rotate([90,0,0])
            {
              translate([0,-depth,-0.8*thumb_segment_lengths[1]])
              {
                cylinder(r=thumb_radius,h=0.8*thumb_segment_lengths[1]);
              }
              translate([0,-depth,-0.8*thumb_segment_lengths[1]])
                sphere(r=thumb_radius);
            }
          // a thumb_radius cutout for a thumb:
          translate(thumb_coords[1])
            rotate(thumb_rotation[1])
            rotate([90,0,0])
            {
              translate([0,0,-1*thumb_segment_lengths[1]])
              {
                cylinder(r1=thumb_radius,r2=1.4*thumb_radius,h=thumb_segment_lengths[1]+0.01);
              }
              translate([0,0,-2*thumb_segment_lengths[1]])
              {
                cylinder(r=thumb_radius,h=2*thumb_segment_lengths[1]);
              }
            }
        }

        translate(thumb_coords[1])
          rotate(thumb_rotation[1])
          rotate([0,90,0])
          {
            rotate([90,0,0])
            difference()
            {
              translate([0,0,-7])
              cylinder(r=(thumb_radius-10+thumb_radius+10-8),h=14);
              translate([0,0,-0.01])
              {
                translate([-2*thumb_radius,-2*thumb_radius,-7-0.01])
                cube([2*thumb_radius,4*thumb_radius,1.02+14]);
                translate([0,0,-7])
                cylinder(r=thumb_radius+1*contact_clearance,h=0.02+14);
              }
            }
            for (trans=[-thumb_radius-10-contact_clearance,thumb_radius+contact_clearance])
              translate([0,0,trans])
              {
                cylinder(r=7,h=10);
            }
          }
      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        mirror([0,0,1])
        {
          translate([0,0,thumb_radius+contact_clearance])
            cylinder(r=frame_radius,h=thumb_connection_point_translation_distance-thumb_radius-contact_clearance,$fn=30);
        }
      }



      // Negative parts of contact:
      // TODO/FIXME: one should be able to use thumb_coords[2] here, and be
      // over with it. That places it in a weird spot though, so...
      translate(thumb_coords[1])
        rotate(thumb_rotation[2])
        translate([0,0.75*thumb_segment_lengths[1],-depth])
        contact_negative();

      // Place the far thumb and near thumb buttons where they need to be:
      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        rotate([0,90,0])
        translate([0,0,-thumb_radius-contact_clearance])
        contact_negative();
      translate(thumb_coords[1])
        rotate(thumb_rotation[1])
        rotate([0,-90,0])
        translate([0,0,-thumb_radius-contact_clearance])
        contact_negative();

    }
    // TODO/FIXME: same comment as with contact_negative
    translate(thumb_coords[1])
      rotate(thumb_rotation[2])
      translate([0,0.75*thumb_segment_lengths[1],-depth])
      contact_positive();

    // Place the far thumb and near thumb buttons where they need to be:
    translate(thumb_coords[1])
      rotate(thumb_rotation[1])
      rotate([0,90,0])
      translate([0,0,-thumb_radius-contact_clearance])
      contact_positive();
    translate(thumb_coords[1])
      rotate(thumb_rotation[1])
      rotate([0,-90,0])
      translate([0,0,-thumb_radius-contact_clearance])
      contact_positive();
  } // }}}

  thumb_contact();




  // TODO:
  // Given the coordinates (and rotation) at the fingertip, simply "extend"
  // something from the knuckles.


  /*
  all_coords = [pinky_coords,ring_coords,middle_coords,index_coords,thumb_coords];
  all_rotation = [pinky_rotation,ring_rotation,middle_rotation,index_rotation,thumb_rotation];
  for (k = [0:4])
  {
    // illustrate that we have coordinates/rotation in mid-joint, for all joints:
    for (i = [0:(k==4 ? 2 : 3)])
    {
      translate(all_coords[k][i])
        rotate(all_rotation[k][i])
        cylinder(r=1,h=5,$fn=10);

      // example placement of a touch button:
      translate(all_coords[k][k==4?2:3])
        rotate(all_rotation[k][k==4?2:3])
        {
          translate([0,0,-20]) // should probably depend on finger radius
          cylinder(r=2,h=10,$fn=20);
        }
      }

  }
  */
} // }}}


module body()
{ // {{{
  body_front_thumb_offset = finger_end_connection_point_thumb;
  body_front_index_offset = index_joint0_offset + [0,-10,-index_radius-frame_radius];
  body_front_pinky_offset = pinky_joint0_offset + [-5,-10,-pinky_radius-frame_radius];

  body_wristaxis_thumbside_offset = wristaxis_thumbside_offset+[0,0,-wristaxis_radius-frame_radius];
  body_wristaxis_pinkyside_offset = wristaxis_pinkyside_offset+[0,0,-wristaxis_radius-frame_radius];

  // A fairly arbitrary point in the middle of the body shape:
  _base_mcu_corner = [
    0.5*middle_joint0_offset[0]+0.5*ring_joint0_offset[0],
    thumb_coords[1][1]-60,
    thumb_coords[1][2]];

  body_mcu_box_corners = [
    _base_mcu_corner + [0.5*mcu_clearance_wdh[0], 0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [0.5*mcu_clearance_wdh[0], -0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [-0.5*mcu_clearance_wdh[0],-0.5*mcu_clearance_wdh[1],0],
    _base_mcu_corner + [-0.5*mcu_clearance_wdh[0],0.5*mcu_clearance_wdh[1],0],
  ];

  difference()
  {
    union()
    {
      for (offs=[
        body_front_index_offset,
        body_front_pinky_offset,
        body_front_thumb_offset,
        finger_end_connection_point_index,
        finger_end_connection_point_pinky,
        body_wristaxis_thumbside_offset,
        body_wristaxis_pinkyside_offset,
        body_mcu_box_corners[0],
        body_mcu_box_corners[1],
        body_mcu_box_corners[2],
        body_mcu_box_corners[3],
        ])
      {
        translate(offs)
        {
          sphere(r=frame_radius,$fn=20);
        }
      }

      translate(finger_end_connection_point_thumb)
        connector_positive();
      translate(finger_end_connection_point_index)
        connector_positive();
      translate(finger_end_connection_point_pinky)
        connector_positive();

      // Connectors in the front:
      cylinder_from_to(
        0.9*body_front_index_offset+0.1*body_wristaxis_thumbside_offset,
        body_front_thumb_offset,
        frame_radius,frame_radius,
        $fn=30);


      cylinder_from_to(
        body_front_index_offset,
        finger_end_connection_point_index,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        finger_end_connection_point_index,
        finger_end_connection_point_pinky,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        finger_end_connection_point_pinky,
        body_front_pinky_offset,
        frame_radius,frame_radius,
        $fn=30);

      // Connectors front to back:

      cylinder_from_to(
        body_front_thumb_offset,
        0.5*body_front_index_offset+0.5*body_wristaxis_thumbside_offset,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        body_front_pinky_offset,
        body_wristaxis_pinkyside_offset,
        frame_radius,frame_radius,
        $fn=30);

      cylinder_from_to(
        body_front_index_offset,
        body_wristaxis_thumbside_offset,
        frame_radius,frame_radius,
        $fn=30);

      // Connectors in the back
      cylinder_from_to(
        body_wristaxis_thumbside_offset,
        body_wristaxis_pinkyside_offset,
        frame_radius,frame_radius,
        $fn=30);

      // Connectors to the MCU
      cylinder_from_to(
        body_front_thumb_offset,
        body_mcu_box_corners[3],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_front_pinky_offset,
        body_mcu_box_corners[0],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_pinkyside_offset,
        body_mcu_box_corners[1],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_wristaxis_thumbside_offset,
        body_mcu_box_corners[2],
        frame_radius,frame_radius,
        $fn=30);
      cylinder_from_to(
        body_front_index_offset,
        body_mcu_box_corners[3],
        frame_radius,frame_radius,
        $fn=30);

      // Connectors around the MCU
      for(i=[0:3])
        cylinder_from_to(
          body_mcu_box_corners[i],
          body_mcu_box_corners[(i+1)%4],
          frame_radius,frame_radius,
          $fn=30);
    }
    union()
    {
      translate(finger_end_connection_point_thumb)
        mirror([0,1,0])
          connector_negative(extra_cutout=true);
      translate(finger_end_connection_point_index)
        mirror([0,1,0])
          connector_negative(extra_cutout=true);
      translate(finger_end_connection_point_pinky)
        mirror([0,1,0])
          connector_negative(extra_cutout=true);
      translate(body_mcu_box_corners[2])
        cube(mcu_clearance_wdh);
      
    }
  }

} // }}}

finger_end();

body();

translate([-40,0,0])
test_object();

% hand_model();
