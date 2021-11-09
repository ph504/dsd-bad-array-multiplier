LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
--------------------------------------------------------------------------------
----------------HDL code for describing a full adder----------------------------
--------------------------------------------------------------------------------
ENTITY fa IS
	PORT(
		a 		: IN  std_logic;
		b 		: IN  std_logic;
		cin		: IN  std_logic;
		y 		: OUT std_logic;
		cout 	: OUT std_logic
	);
END fa;

ARCHITECTURE dataflow OF fa IS
	SIGNAL sum 	: std_logic_vector(1 DOWNTO 0);
BEGIN
	
	-- summation
	sum 	<= ('0'&a) + ('0'&b) + ('0'&cin);
	y 		<= sum(0);
	cout    <= sum(1);
			
END dataflow; 

--------------------------------------------------------------------------------
--------------HDL code for describing an Array Multiplier-----------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY mult_array IS
	GENERIC (N  : integer := 32);
	PORT(
		a 		: IN  std_logic_vector(N-1   DOWNTO 0);
		b 		: IN  std_logic_vector(N-1   DOWNTO 0);
		y 		: OUT std_logic_vector(2*N-1 DOWNTO 0)
	);
END mult_array;

ARCHITECTURE generative OF mult_array IS
	COMPONENT fa IS
		PORT(
			a 		: IN  std_logic;
			b 		: IN  std_logic;
			cin		: IN  std_logic;
			y 		: OUT std_logic;
			cout 	: OUT std_logic
		);
	END COMPONENT fa;
	TYPE PARTIAL 	 IS ARRAY (0 TO N-1  ,0 TO N-1  ) OF std_logic;
	TYPE nMultMatrix IS ARRAY (0 TO N-1  ,0 TO 2*N-1) OF std_logic;
	TYPE nSumOut 	 IS ARRAY (0 TO N    ,0 TO 2*N-1) OF std_logic;
	TYPE nCarryOut   IS ARRAY (0 TO N-1  ,0 TO 2*N  ) OF std_logic;

	-- the partial product of each bit, is the bitwise and of the input signals.
-- 	SIGNAL p 	: PARTIAL;

	-- the extended partial product (or generated partial product) which has dummy bits to complete the generation loop for full adders withtout the need to insert half adders.
 	SIGNAL pg	: nMultMatrix;

 	-- this is a signal for the summation output and input from and to each full adder in the hardware.
 	SIGNAL dout	: nSumOut;

 	-- this is a signal for the carry output and input from and to each full adder in the hardware.
 	SIGNAL cin 	: nCarryOut;
 	
BEGIN

	g_column : FOR k IN 0 TO 2*N-1 GENERATE				-- loop of calculating each value of mult bit.
		
		dout(0,k) <= '0';

		g_adders : FOR i IN 0 TO N-1 GENERATE 			-- loop of describing full adders together in one column.

			g_pg_init1 : FOR j IN i TO i+N-1 GENERATE
				pg(i,j) <= a(i) AND b(j-i);
			END GENERATE g_pg_init1;

			g_pg_init2 : FOR j IN 0 TO i-1 GENERATE
				pg(i,j) <= '0';
			END GENERATE g_pg_init2;

			g_pg_init3 : FOR j IN i+N TO 2*N-1 GENERATE
				pg(i,j) <= '0';
			END GENERATE g_pg_init3;
			--pg(i,k)  <= '0' WHEN (k>i+N-1 or k<i) ELSE (a(i) AND b(k-i)); -- i+N-1 >= k >= i
			--pg <= (i+N-1 DOWNTO i => (a(i) AND b(i)),OTHERS => (OTHERS => '0'));

			cin(i,0) <= '0';

			genfa : fa
				PORT MAP(
					a    => pg	 (i  ,k  ),
					b    => dout (i  ,k  ),
					cin  => cin	 (i  ,k  ),
					y    => dout (i+1,k  ),
					cout => cin	 (i  ,k+1)
			);

		END GENERATE g_adders;

		y(k) <= dout(N-1,k);

	END GENERATE g_column;

END generative;

--------------------------------------------------------------------------------
--------------HDL code for describing an Array Multiplier Testbench-------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL; 

ENTITY mult_array_tb IS
END mult_array_tb;

ARCHITECTURE test OF mult_array_tb IS
	
	COMPONENT mult_array IS
		GENERIC (N    : integer := 32);
		PORT(
				 a 	  : IN  std_logic_vector(N-1   DOWNTO 0);
				 b 	  : IN  std_logic_vector(N-1   DOWNTO 0);
				 y 	  : OUT std_logic_vector(2*N-1 DOWNTO 0)
		);
	END COMPONENT mult_array;
	CONSTANT 	 N    : integer := 32;
	SIGNAL 		 a_tb :	std_logic_vector(N-1 	 DOWNTO 0);
	SIGNAL 		 b_tb :	std_logic_vector(N-1 	 DOWNTO 0);
	SIGNAL 		 y_tb :	std_logic_vector(2*N-1   DOWNTO 0);
BEGIN
	CUT : mult_array 
	GENERIC MAP(
		N=> N
	)
	PORT MAP(
		a=> a_tb,
		b=> b_tb,
		y=> y_tb
	);
--	a_tb(0 TO 3)   <= X"5";
	a_tb <= (N-1 DOWNTO 4 => '0')&X"5", (N-1 DOWNTO 8 => '0')&X"03" AFTER 80 ns;

--	b_tb(0 TO 3)   <= X"3";
	b_tb <= (N-1 DOWNTO 4 => '0')&X"3", (N-1 DOWNTO 8 => '0')&X"D1" AFTER 40 ns;
END test;