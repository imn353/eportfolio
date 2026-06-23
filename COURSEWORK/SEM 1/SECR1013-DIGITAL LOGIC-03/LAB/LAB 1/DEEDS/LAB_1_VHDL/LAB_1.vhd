------------------------------------------------------------
-- Deeds (Digital Electronics Education and Design Suite)
-- VHDL Code generated on (4/11/2023, 4:30:55 PM)
--      by Deeds (Digital Circuit Simulator)(Deeds-DcS)
--      Ver. 2.50.200 (Feb 18, 2022)
-- Copyright (c) 2002-2022 University of Genoa, Italy
--      Web Site:  https://www.digitalelectronicsdeeds.com
------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;


ENTITY LAB_1 IS
  PORT( 
    --------------------------------------> Inputs:
    iA:           IN  std_logic;
    iB:           IN  std_logic;
    iA_0:         IN  std_logic;
    iB_0:         IN  std_logic;
    iA_1:         IN  std_logic;
    iB_1:         IN  std_logic;
    --------------------------------------> Outputs:
    ooF:          OUT std_logic;
    ooF_0:        OUT std_logic;
    ooF_1:        OUT std_logic 
    ------------------------------------------------------
    );
END LAB_1;


ARCHITECTURE structural OF LAB_1 IS 

  ----------------------------------------> Components:
  COMPONENT NOT_gate IS
    PORT( I: IN std_logic;
          O: OUT std_logic );
  END COMPONENT;
  --
  COMPONENT AND2_gate IS
    PORT( I0,I1: IN std_logic;
          O: OUT std_logic );
  END COMPONENT;
  --
  COMPONENT OR2_gate IS
    PORT( I0,I1: IN std_logic;
          O: OUT std_logic );
  END COMPONENT;

  ----------------------------------------> Signals:
  SIGNAL S001: std_logic;
  SIGNAL S002: std_logic;
  SIGNAL S003: std_logic;
  SIGNAL S004: std_logic;
  SIGNAL S005: std_logic;
  SIGNAL S006: std_logic;
  SIGNAL S007: std_logic;
  SIGNAL S008: std_logic;
  SIGNAL S009: std_logic;
  SIGNAL S010: std_logic;
  SIGNAL S011: std_logic;
  SIGNAL S012: std_logic;
  SIGNAL S013: std_logic;
  SIGNAL S014: std_logic;


BEGIN -- structural

  ----------------------------------------> Input:
  S001 <= iA;
  S002 <= iB;
  S003 <= iA_0;
  S004 <= iB_0;
  S007 <= iA_1;
  S008 <= iB_1;

  ----------------------------------------> Output:
  ooF <= S006;
  ooF_0 <= S014;
  ooF_1 <= S013;

  ----------------------------------------> Component Mapping:
  C005: AND2_gate PORT MAP ( S001, S002, S006 );
  C032: AND2_gate PORT MAP ( S003, S004, S005 );
  C033: NOT_gate PORT MAP ( S005, S014 );
  C053: NOT_gate PORT MAP ( S008, S009 );
  C054: NOT_gate PORT MAP ( S007, S010 );
  C055: AND2_gate PORT MAP ( S007, S009, S011 );
  C056: AND2_gate PORT MAP ( S010, S008, S012 );
  C057: OR2_gate PORT MAP ( S011, S012, S013 );
END structural;
