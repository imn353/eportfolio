------------------------------------------------------------
-- Deeds (Digital Electronics Education and Design Suite)
-- VHDL Code generated on (4/11/2023, 4:30:55 PM)
--      by Deeds (Digital Circuit Simulator)(Deeds-DcS)
--      Ver. 2.50.200 (Feb 18, 2022)
-- Copyright (c) 2002-2022 University of Genoa, Italy
--      Web Site:  https://www.digitalelectronicsdeeds.com
------------------------------------------------------------

--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

ENTITY NOT_gate IS
  PORT( I: IN std_logic;
  	O: OUT std_logic );
END NOT_gate;

--------------------------------------------------------------------
ARCHITECTURE behavioral OF NOT_gate IS
BEGIN
  O <= (not I);
END behavioral;



--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

ENTITY AND2_gate IS
  PORT( I0,I1: IN std_logic;
        O: OUT std_logic );
END AND2_gate;

--------------------------------------------------------------------
ARCHITECTURE behavioral OF AND2_gate IS
BEGIN
  O <= (I0 and I1);
END behavioral;


--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

ENTITY OR2_gate IS
  PORT( I0,I1: IN std_logic;
        O: OUT std_logic );
END OR2_gate;

--------------------------------------------------------------------
ARCHITECTURE behavioral OF OR2_gate IS
BEGIN
  O <= (I0 or I1);
END behavioral;



