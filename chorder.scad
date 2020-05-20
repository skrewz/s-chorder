

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
// TODO: how does one measure these?
pinky_segment_lengths  = [ 53,  32, 28 ];
ring_segment_lengths   = [ 65,  40, 33 ];
middle_segment_lengths = [ 69,  44, 31 ];
index_segment_lengths  = [ 65,  39, 31 ];
thumb_segment_lengths  = [ 54,  51 ];

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
  [x_coord_for(startvec,angle,segment,radius),y_coord_for(startvec,angle,segment,radius),z_coord_for(startvec,angle,segment,radius)];

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
_thumb_coord_1 = coord_for(thumb_joint0_offset,sum([for (i=[0:0]) thumb_angles[i]]),thumb_segment_lengths[0],thumb_radius);
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
        segment(thumb_segment_lengths[0]-2*thumb_radius,thumb_radius);
        translate([0,0,thumb_segment_lengths[0]-2*thumb_radius])
          rotate([-thumb_angles[1],0,0])
            final_segment(thumb_segment_lengths[1]-thumb_radius,thumb_radius);
      }
    }
  }

  cylinder_from_to(thumb_joint0_offset,index_joint0_offset,thumb_radius,index_radius,$fn=40);
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

module chorder()
{ // {{{


  // TODO:
  // Given the coordinates (and rotation) at the fingertip, simply "extend"
  // something from the knuckles.



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
          #
          cylinder(r=2,h=10,$fn=20);
        }
      }
  }
} // }}}


chorder();

% hand_model();
