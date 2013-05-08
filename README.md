Webcam-Robust-Tracking
======================

Final project for 16-385 Computer Vision. Once complete, will allow for tracking and shooting a custom NERF gun turret using a low-resolution webcam.

Architecture 
----------------------

turret.m - top-level class for turret.
bg_tracker.m - for background model generation and position estimation
detect_objects.m - for blob-based object detection



Test Files 
----------------------
All tests without the word 'webcam' can be run without the turret
actually connected to the computer. These tests demonstrate 
the correctness and robustness of various parts the nerf turret
software, including:

background tracking (test_bg_tracker.m)
blob detection      (test_detect_objects.m)
tracking            (test_turret_tracking.m)

Other tests (like test_keyboard_input.m) actually test parts
of the test scripts. Cyclic, yes, but necessary.