-------------------------------------------------------------------------------
--  File name : testbench_s25hs01gt_verilog.vhd
-------------------------------------------------------------------------------
--  Copyright (C) 2017 Cypress Semiconductor Corporation
--
--  MODIFICATION HISTORY :
--
--  version:   |     author:     |   mod date:  |  changes made:
--   V1.0            B.Barac         18 June 28      Inital Release
--   V1.1            B.Barac         18 July 23      Updated according rev *I 
--                                                   (aded QPI legacy reset, 
--                                                   changed some register default value
--                                                   and sfdp)
--   V1.2            B.Barac         18 Oct 05       Updated according rev *I 
--                                                   (fixed minor errors in sfdp
--                                                   Address : 110h,14Eh,14Fh)
--   V1.3            M.Krneta        19 Feb 14       Updated according to the rev *L
--                                                   (SFDP, timings, transaction table)
--   V1.4            M.Krneta        19 Aug 16       Updated according to the rev *R
--                                                   (SFDP, timings)
--   V1.5            M.Krneta        19 Dec 13       Bit-walking bug fixed
--   V1.6            S.Stevanovic    03 Oct 20       Update to revision *X
--                                                   (SFDP only),
--                                                   Removing dependency between
--                                                   QUADIT and QPI
--   V1.7			 N. Naim         11 Apr 22		 Added h_io3_reset and bus_io3_reset
--													 for DQ3 reset pin
--   V1.8        	 N. Naim       	 22 May 18       Update on CS# signaling reset
-------------------------------------------------------------------------------
--  PART DESCRIPTION:
--
--  Description:
--             Generic test enviroment for verification of flash memory
--             VITAL models.
--
-------------------------------------------------------------------------------
--  Comments :
--      * For correct simulation, simulator resolution should be set to 1ps.
--      * When testing with different timing models, value of CONSTANT
--        Timingmodel should be changed
--      * When testing with different hybrid sector architecture, value of
--        CONSTANT BootConfig should be changed. Possible values are
--        TRUE for BottomBoot i FALSE for TopBoot; TopAndBottom*
-------------------------------------------------------------------------------
--  Known Bugs:
--
-------------------------------------------------------------------------------
--  Notes:
--  Choose value for variable 'Clock_polarity' to select SPI mode
--    Clock_polarity <= '0'; for SPI mode: CPO L= 0, CPHA = 0
--    Clock_polarity <= '1'; for SPI mode: CPO L= 1, CPHA = 1
--  Set test environment - device protection mode
--    MODE <= DEFAULT_PROTECTION;
--    MODE <= PERSISTENT_PROTECTION;
--    MODE <= PASSWORD_PROTECTION;
--    MODE <= SEERC_READ;
--    MODE <= TEST_JEDEC_RESET;
--    MODE <= AUTOBOOT_TEST;
--    MODE <= PROGRAM_PPB_QPI;
-------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.std_logic_1164.ALL;
    USE IEEE.VITAL_timing.ALL;
    USE IEEE.VITAL_primitives.ALL;
    USE STD.textio.ALL;

LIBRARY FMF;
    USE FMF.gen_utils.all;
    USE FMF.conversions.all;

LIBRARY work;
    USE work.spansion_tc_pkg.all;
-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY testbench_s25hs01gt_verilog IS

END testbench_s25hs01gt_verilog;
-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE vhdl_behavioral_static_memory_allocation
                                              of testbench_s25hs01gt_verilog IS
    COMPONENT s25hs01gt IS
        GENERIC (

        -- memory file to be loaded
        mem_file_name     : STRING    := "s25hs01gt.mem";
        otp_file_name     : STRING    := "s25hs01gtOTP.mem";

        UserPreload       : INTEGER   := 1;

        -- For FMF SDF technology file usage
        TimingModel       : STRING    := DefaultTimingModel
    );
    PORT (
        -- Data Inputs/Outputs
        SI                : INOUT std_ulogic := 'U'; -- serial data input/IO0
        SO                : INOUT std_ulogic := 'U'; -- serial data output/IO1
        -- Controls
        SCK               : IN    std_ulogic := 'U'; -- serial clock input
        CSNeg             : IN    std_ulogic := 'U'; -- chip select input
        RESETNeg          : INOUT std_ulogic := 'U'; -- hardware reset pin
        WPNeg             : INOUT std_ulogic := 'U'; -- write protect input/IO2
        IO3_RESETNeg      : INOUT std_ulogic := 'U'  -- hold input/IO3
    );
    END COMPONENT s25hs01gt;

    FOR ALL: s25hs01gt USE ENTITY work.s25hs01gt;
    ---------------------------------------------------------------------------
    --memory configuration
    ---------------------------------------------------------------------------
    CONSTANT MaxData       : NATURAL := 16#FF#;        --255;
    CONSTANT MemSize       : NATURAL := 16#7FFFFFF#;
    CONSTANT SecNumUni     : NATURAL := 511;
    CONSTANT SecNumHyb     : NATURAL := 543;
    CONSTANT SecSize4      : NATURAL := 16#FFF#;
    CONSTANT SecSize256    : NATURAL := 16#3FFFF#;
    CONSTANT PageNum512    : NATURAL := 16#1FFFF#;
    CONSTANT PageNum256    : NATURAL := 16#3FFFF#;
    CONSTANT AddrRANGE     : NATURAL := 16#7FFFFFF#;
    CONSTANT HiAddrBit     : NATURAL := 31;
    CONSTANT OTPSize       : NATURAL := 1023;
    CONSTANT OTPLoAddr     : NATURAL := 16#000#;
    CONSTANT OTPHiAddr     : NATURAL := 16#3FF#;
    CONSTANT SFDPSize      : NATURAL := 16#0247#;
    CONSTANT SFDPLoAddr    : NATURAL := 16#0000#;
    CONSTANT SFDPHiAddr    : NATURAL := 16#0247#;

    ---------------------------------------------------------------------------
    --model configuration
    ---------------------------------------------------------------------------
    CONSTANT mem_file           :   string  := "s25hs01gt.mem";
    CONSTANT otp_file           :   string  := "s25hs01gtOTP.mem";
    CONSTANT half_period1_srl   :   time    := 3.01 ns;   --1/(2*166MHz)
    CONSTANT half_period2_srl   :   time    := 10 ns;     --1/(2*50MHz)
    CONSTANT half_period3_srl   :   time    := 3.76 ns;   --1/(2*133MHz)
    CONSTANT half_period_ddr    :   time    := 4.9 ns;    --1/(2*102MHz)
    CONSTANT half_period2_ddr   :   time    := 6.02 ns;   --1/(2*83MHz)
    CONSTANT half_period3_ddr   :   time    := 7.58 ns;   --1/(2*66MHz)
    CONSTANT half_period_30pF   :   time    := 4.24 ns;   --

    CONSTANT UserPreload        :   integer :=  1;
    CONSTANT LongTimming        :   boolean :=  FALSE;
    CONSTANT TimingModel        :   STRING  :=  "S25HS01GTDSMHI010_30pF";
    CONSTANT BootConfig         :   boolean :=  TRUE;
    CONSTANT TopAndBottom       :   boolean :=  FALSE;
    CONSTANT tcss               :   time    := 10 ns;
    CONSTANT tcssh              :   time    := 0 ns;
    ---------------------------------------------------------------------------
    --One Byte Instruction Code
    ---------------------------------------------------------------------------
    CONSTANT I_WRR          :std_logic_vector(7 downto 0) := "00000001";-- 01h
    CONSTANT I_PP           :std_logic_vector(7 downto 0) := "00000010";-- 02h
    CONSTANT I_READ         :std_logic_vector(7 downto 0) := "00000011";-- 03h
    CONSTANT I_WRDI         :std_logic_vector(7 downto 0) := "00000100";-- 04h
    CONSTANT I_RDSR1        :std_logic_vector(7 downto 0) := "00000101";-- 05h
    CONSTANT I_WREN         :std_logic_vector(7 downto 0) := "00000110";-- 06h
    CONSTANT I_RDSR2        :std_logic_vector(7 downto 0) := "00000111";-- 07h
    CONSTANT I_PP4          :std_logic_vector(7 downto 0) := "00010010";-- 12h
    CONSTANT I_READ4        :std_logic_vector(7 downto 0) := "00010011";-- 13h
    CONSTANT I_ABWR         :std_logic_vector(7 downto 0) := "00010101";-- 15h
    CONSTANT I_REDUS4       :std_logic_vector(7 downto 0) := "00011000";-- 18h
    CONSTANT I_REDUS        :std_logic_vector(7 downto 0) := "00011001";-- 19h
    CONSTANT I_CLECC        :std_logic_vector(7 downto 0) := "00011011";-- 1Bh
    CONSTANT I_P4E          :std_logic_vector(7 downto 0) := "00100000";-- 20h
    CONSTANT I_P4E4         :std_logic_vector(7 downto 0) := "00100001";-- 21h
    CONSTANT I_30h          :std_logic_vector(7 downto 0) := "00110000";-- 30h
    CONSTANT I_RDCR1        :std_logic_vector(7 downto 0) := "00110101";-- 35h
    CONSTANT I_DOR          :std_logic_vector(7 downto 0) := "00111011";-- 3Bh
    CONSTANT I_DOR4         :std_logic_vector(7 downto 0) := "00111100";-- 3Ch
    CONSTANT I_DLPRD        :std_logic_vector(7 downto 0) := "01000001";-- 41h
    CONSTANT I_OTPP         :std_logic_vector(7 downto 0) := "01000010";-- 42h
    CONSTANT I_PNVDLR       :std_logic_vector(7 downto 0) := "01000011";-- 43h
    CONSTANT I_BE_60        :std_logic_vector(7 downto 0) := "01100000";-- 60h
    CONSTANT I_RDAR         :std_logic_vector(7 downto 0) := "01100101";-- 65h
    CONSTANT I_RSTEN        :std_logic_vector(7 downto 0) := "01100110";-- 66h
    CONSTANT I_QOR          :std_logic_vector(7 downto 0) := "01101011";-- 6Bh
    CONSTANT I_QOR4         :std_logic_vector(7 downto 0) := "01101100";-- 6Ch
    CONSTANT I_WRAR         :std_logic_vector(7 downto 0) := "01110001";-- 71h
    CONSTANT I_EPS_75       :std_logic_vector(7 downto 0) := "01110101";-- 75h
    CONSTANT I_CLSR         :std_logic_vector(7 downto 0) := "10000010";-- 82h
    CONSTANT I_EPS_85       :std_logic_vector(7 downto 0) := "10000101";-- 85h
    CONSTANT I_RST          :std_logic_vector(7 downto 0) := "10011001";-- 99h
    CONSTANT I_FAST_READ    :std_logic_vector(7 downto 0) := "00001011";-- 0Bh
    CONSTANT I_FAST_READ4   :std_logic_vector(7 downto 0) := "00001100";-- 0Ch
    CONSTANT I_ASPP         :std_logic_vector(7 downto 0) := "00101111";-- 2Fh
    CONSTANT I_WVDLR        :std_logic_vector(7 downto 0) := "01001010";-- 4Ah
    CONSTANT I_OTPR         :std_logic_vector(7 downto 0) := "01001011";-- 4Bh
    CONSTANT I_RUID         :std_logic_vector(7 downto 0) := "01001100";-- 4Ch
    CONSTANT I_WRENV        :std_logic_vector(7 downto 0) := "01010000";-- 50h
    CONSTANT I_RSFDP        :std_logic_vector(7 downto 0) := "01011010";-- 5Ah
    CONSTANT I_DIC          :std_logic_vector(7 downto 0) := "01011011";-- 5Bh
    CONSTANT I_SEERC        :std_logic_vector(7 downto 0) := "01011101";-- 5Dh
    CONSTANT I_EPR_7A       :std_logic_vector(7 downto 0) := "01111010";-- 7Ah
    CONSTANT I_EPR_8A       :std_logic_vector(7 downto 0) := "10001010";-- 8Ah
    CONSTANT I_RDID         :std_logic_vector(7 downto 0) := "10011111";-- 9Fh
    CONSTANT I_PLBWR        :std_logic_vector(7 downto 0) := "10100110";-- A6h
    CONSTANT I_PLBRD        :std_logic_vector(7 downto 0) := "10100111";-- A7h
    CONSTANT I_RDQID        :std_logic_vector(7 downto 0) := "10101111";-- AFh
    CONSTANT I_EPS_B0       :std_logic_vector(7 downto 0) := "10110000";-- B0h
    CONSTANT I_BAM4         :std_logic_vector(7 downto 0) := "10110111";-- B7h
    CONSTANT I_EX4BA_0_0    :std_logic_vector(7 downto 0) := "10111000";-- B8h
    CONSTANT I_DPD          :std_logic_vector(7 downto 0) := "10111001";-- B9h
    CONSTANT I_DIOR         :std_logic_vector(7 downto 0) := "10111011";-- BBh
    CONSTANT I_DIOR4        :std_logic_vector(7 downto 0) := "10111100";-- BCh
    CONSTANT I_SBL          :std_logic_vector(7 downto 0) := "11000000";-- C0h
    CONSTANT I_BE_C7        :std_logic_vector(7 downto 0) := "11000111";-- C7h
    CONSTANT I_EES          :std_logic_vector(7 downto 0) := "11010000";-- D0h
    CONSTANT I_SE           :std_logic_vector(7 downto 0) := "11011000";-- D8h
    CONSTANT I_SE4          :std_logic_vector(7 downto 0) := "11011100";-- DCh
    CONSTANT I_DYBRD4       :std_logic_vector(7 downto 0) := "11100000";-- E0h
    CONSTANT I_DYBWR4       :std_logic_vector(7 downto 0) := "11100001";-- E1h
    CONSTANT I_PPBRD4       :std_logic_vector(7 downto 0) := "11100010";-- E2h
    CONSTANT I_PPBP4        :std_logic_vector(7 downto 0) := "11100011";-- E3h
    CONSTANT I_PPBERS       :std_logic_vector(7 downto 0) := "11100100";-- E4h
    CONSTANT I_PASSP        :std_logic_vector(7 downto 0) := "11101000";-- E8h
    CONSTANT I_PASSU        :std_logic_vector(7 downto 0) := "11101001";-- E9h
    CONSTANT I_RDQIOR       :std_logic_vector(7 downto 0) := "11101011";-- EBh
    CONSTANT I_RDQIOR4      :std_logic_vector(7 downto 0) := "11101100";-- ECh
    CONSTANT I_DDRQIOR      :std_logic_vector(7 downto 0) := "11101101";-- EDh
    CONSTANT I_DDRQIOR4     :std_logic_vector(7 downto 0) := "11101110";-- EEh
    CONSTANT I_RESET        :std_logic_vector(7 downto 0) := "11110000";-- F0h
    CONSTANT I_DYBRD        :std_logic_vector(7 downto 0) := "11111010";-- FAh
    CONSTANT I_DYBWR        :std_logic_vector(7 downto 0) := "11111011";-- FBh
    CONSTANT I_PPBRD        :std_logic_vector(7 downto 0) := "11111100";-- FCh
    CONSTANT I_PPBP         :std_logic_vector(7 downto 0) := "11111101";-- FDh
    CONSTANT I_MBR          :std_logic_vector(7 downto 0) := "11111111";-- FFh

    ---------------------------------------------------------------------------
    --testbench parameters
    ---------------------------------------------------------------------------
    --Flash Memory Array
    TYPE MemArr IS ARRAY (0 TO AddrRANGE)      OF integer RANGE -1 TO MaxData;
    --OTP Array
    TYPE OtpArr IS ARRAY (OTPLoAddr TO OTPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;
    --CFI Array
    TYPE CFIArr IS ARRAY (16#00# TO 16#8E#) OF integer RANGE -1 TO MaxData;

    --SFDP Array
    TYPE SFDPArr IS ARRAY (SFDPLoAddr TO SFDPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;

    ---------------------------------------------------------------------------
    --  memory declaration
    ---------------------------------------------------------------------------
    --             -- Mem(SecAddr)(Address)....
    SHARED  VARIABLE Mem             : MemArr := (OTHERS => MaxData);
    SHARED  VARIABLE Otp             : OtpArr := (OTHERS => MaxData);
    SHARED  VARIABLE CFI_array       : CFIArr;
    SHARED  VARIABLE SFDP_array      : SFDPArr;
    SHARED  VARIABLE half_period     : TIME     := half_period1_srl;--3.01 ns
    SHARED  VARIABLE CSNEG_time      : TIME     := 0 ns;
    SHARED  VARIABLE SO_time         : TIME     := 0 ns;
    SHARED  VARIABLE sdf_max_param   : boolean := FALSE;
    SHARED  VARIABLE sdf_max_param15 : boolean := FALSE;
    SHARED  VARIABLE sdf_max_param30 : boolean := FALSE;
    SHARED  VARIABLE sdf_min_param   : boolean := FALSE;
    SHARED  VARIABLE sdf_min_param15   : boolean := FALSE;
    SHARED  VARIABLE DisableClock    : BOOLEAN    := FALSE;
    
    SHARED VARIABLE Lat_cnt     : NATURAL;
    
    SIGNAL           tcss_expired    : std_logic  := '0';
    SIGNAL           tcssh_expired   : std_logic  := '0';

    --command sequence
    SHARED VARIABLE cmd_seq         : cmd_seq_type;

    SIGNAL status          : status_type := none;
    SIGNAL cmd             : cmd_type := idle;
    SIGNAL read_num        : NATURAL := 0;

    -- device protection mode
    TYPE protection_type IS ( DEFAULT_PROTECTION,
                              PERSISTENT_PROTECTION,
                              PASSWORD_PROTECTION,
                              PASSWORD_PROTECTION_QPI,
                              SEERC_READ,
                              TEST_JEDEC_RESET,
                              AUTOBOOT_TEST,
                              PROGRAM_PPB_QPI);

    SIGNAL MODE            : protection_type;

    SIGNAL Clock_polarity  : std_logic;
    SIGNAL CSNeg_flag      : std_logic;
    SIGNAL PageSize        :   NATURAL :=  256 ;
    SIGNAL PageNum         :   NATURAL :=  0 ;

    SIGNAL check_err       :   std_logic := '0'; -- Active high on error
    SIGNAL ErrorInTest     :   std_logic := '0';

    ---------------------------------------------------------------------------
    --Personality module:
    --
    --  instanciates the DUT module and adapts generic test signals to it
    ---------------------------------------------------------------------------
    --DUT port
    SIGNAL T_SCK                : std_logic := 'U';
    SIGNAL T_SI                 : std_logic := 'U';
    SIGNAL T_SO                 : std_logic := 'U';

    SIGNAL T_CSNeg_mx           : std_logic := 'U';
    SIGNAL T_CSNeg              : std_logic := 'U';
    SIGNAL T_CSNeg_jr           : std_logic := 'U';
    SIGNAL jedec_reset_active   : std_logic := '0';
    SIGNAL T_RESETNeg           : std_logic := '1';
    SIGNAL T_WPNeg              : std_logic := '1';
    SIGNAL T_IO3RESETNeg        : std_logic := '1';
    
    SIGNAL debug_signal    : std_logic := '0';
    SIGNAL debug_check    : std_logic := '0';

    SHARED VARIABLE MAX30    : std_logic := '0';
    SHARED VARIABLE DEBUG    : integer := 0;
    SHARED VARIABLE DEBUG1   : integer := 0;

    --Sector Protection Status
    SHARED VARIABLE Sec_Prot     : std_logic_vector (SecNumHyb downto 0) :=
                                                    (OTHERS => '0');
    -----------------------------------------------------------------------
    -- Registers
    -----------------------------------------------------------------------
    --     ***  Status Register 1  ***

    -- Nonvolatile Status Register 1
    SHARED VARIABLE  STR1N   : std_logic_vector(7 downto 0)   := (others => '0');

    ALIAS SRWD_NV      :std_logic IS STR1N(7);
    ALIAS BP2_NV       :std_logic IS STR1N(4);
    ALIAS BP1_NV       :std_logic IS STR1N(3);
    ALIAS BP0_NV       :std_logic IS STR1N(2);

    -- Volatile Status Register 1
    SHARED VARIABLE  STR1V   : std_logic_vector(7 downto 0)   := (others => '0');

    -- Status Register Write Disable Bit
    ALIAS SRWD      :std_logic IS STR1V(7);
    -- Status Register Programming Error Bit
    ALIAS P_ERR     :std_logic IS STR1V(6);
    -- Status Register Erase Error Bit
    ALIAS E_ERR     :std_logic IS STR1V(5);
    -- Status Register Block Protection Bits
    ALIAS BP2       :std_logic IS STR1V(4);
    ALIAS BP1       :std_logic IS STR1V(3);
    ALIAS BP0       :std_logic IS STR1V(2);
    -- Status Register Write Enable Latch Bit
    ALIAS WEL       :std_logic IS STR1V(1);
    -- Status Register Write In Progress Bit
    ALIAS WIP       :std_logic IS STR1V(0);
    
    SHARED VARIABLE  WVREG : std_logic := '0';

    -- Volatile Status Register 2
    SHARED VARIABLE STR2V   : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- DIC Suspend
    ALIAS DICS      :std_logic IS STR2V(4);
    -- DIC Abort
    ALIAS DICA      :std_logic IS STR2V(3);
    -- Erase status
    ALIAS ESTAT     :std_logic IS STR2V(2);
    -- Erase suspend
    ALIAS ES        :std_logic IS STR2V(1);
    -- Program suspend
    ALIAS PS        :std_logic IS STR2V(0);

    -- Nonvolatile Configuration Register 1
    SHARED VARIABLE CFR1N   : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- Split Parameter Sectors both Top and Bottom
    ALIAS SPARM_NV  :std_logic IS CFR1N(6);
    -- Configuration Register TBPROT bit
    ALIAS TBPROT_NV :std_logic IS CFR1N(5);
    -- Configuration Register LOCK bit
    ALIAS LOCK_O    :std_logic IS CFR1N(4);
    -- Configuration Register BPNV bit
    ALIAS BPNV_O    :std_logic IS CFR1N(3);
    -- Configuration Register TBPARM bit
    ALIAS TBPARM_NV :std_logic IS CFR1N(2);
    -- Configuration Register QUAD bit
    ALIAS QUAD_NV   :std_logic IS CFR1N(1);

    --Volatile Configuration Register 1
    SHARED VARIABLE CFR1V    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- Split Parameter Sectors both Top and Bottom
    ALIAS SPARM     :std_logic IS CFR1V(6);
    -- Configuration Register TBPROT bit
    ALIAS TBPROT    :std_logic IS CFR1V(5);
    -- Configuration Register LOCK bit
    ALIAS LOCK      :std_logic IS CFR1V(4);
    -- Configuration Register BPNV bit
    ALIAS BPNV      :std_logic IS CFR1V(3);
    -- Configuration Register TBPARM bit
    ALIAS TBPARM    :std_logic IS CFR1V(2);
    -- Configuration Register QUAD bit
    ALIAS QUAD      :std_logic IS CFR1V(1);
    -- Configuration Register FREEZE bit
    ALIAS FREEZE    :std_logic IS CFR1V(0);

    -- Nonvolatile Configuration Register 2
    SHARED VARIABLE CFR2N   : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Volatile Configuration Register 2
    SHARED VARIABLE CFR2V    : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Configuration Register 2 QPI bit
    ALIAS  QPI    :std_logic IS CFR2V(6);

    -- Nonvolatile Configuration Register 3
    SHARED VARIABLE CFR3N   : std_logic_vector(7 downto 0)
                                            := "00000000";
    -- Volatile Configuration Register 3
    SHARED VARIABLE CFR3V   : std_logic_vector(7 downto 0)
                                            := "00000000";
    -- Nonvolatile Configuration Register 4
    SHARED VARIABLE CFR4N   : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Volatile Configuration Register 4
    SHARED VARIABLE CFR4V   : std_logic_vector(7 downto 0)
                                            := "00001000";
    --  VDLR Register
    SHARED VARIABLE VDLR_reg    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- NVDLR Register
    SHARED VARIABLE NVDLR_reg     : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- ASP Register
    SHARED VARIABLE ASP_reg        : std_logic_vector(15 downto 0)
                                                    := (others => '1');
    --Read Password Mode Enable Bit
    ALIAS RPME      :std_logic IS ASP_reg(5);
    --DYB Lock Boot Bit
    ALIAS DYBLBB      :std_logic IS ASP_reg(4);
    --PPB OTP Bit
    ALIAS PPBOTP    :std_logic IS ASP_reg(3);
    -- Password Protection Mode Lock Bit
    ALIAS PWDMLB    :std_logic IS ASP_reg(2);
    --Persistent Protection Mode Lock Bit
    ALIAS PSTMLB    :std_logic IS ASP_reg(1);
    --Permanent Protection Lock bit
    ALIAS PERMLB    :std_logic IS ASP_reg(0);

    --      ***  Password Register  ***
    SHARED VARIABLE Password_reg   : std_logic_vector(63 downto 0)
                                            := (others => '1');
    --      ***  PPB Lock Register  ***
    SHARED VARIABLE PPBL           : std_logic_vector(7 downto 0)
                                            := "00000001";
    --Persistent Protection Mode Lock Bit
    ALIAS PPB_LOCK                  : std_logic IS PPBL(0);

    --      ***  PPB Access Register  ***
    SHARED VARIABLE PPBAR          : std_logic_vector(7 downto 0)
                                            := (others => '1');
    -- PPB_bits(Sec)
    SHARED VARIABLE PPB_bits       : std_logic_vector(SecNumHyb downto 0)
                                            := (OTHERS => '1');
    --      ***  DYB Access Register  ***
    SHARED VARIABLE DYBAR          : std_logic_vector(7 downto 0)
                                            := (others => '1');
    -- DYB(Sec)
    SHARED VARIABLE DYB_bits       : std_logic_vector(SecNumHyb downto 0)
                                            := (others => '1');
    --      ***  AutoBoot Register  ***
    SHARED VARIABLE AutoBoot_reg   : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --AutoBoot Enable Bit
    ALIAS ABE       :std_logic IS AutoBoot_reg(0);

    --      ***  Bank Address Register  ***
    SHARED VARIABLE Bank_Addr_reg  : std_logic_vector(7 downto 0)
                                            := (others => '0');
    --      ***  Pointer Address Registers  ***
    SHARED VARIABLE PNT_ADR_reg_0  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_1  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_2  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_3  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --      ***  Address Trap Register  ***
    SHARED VARIABLE ADDTRAP_reg    : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE DIC_reg        : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --      ***  Sector Erase Count Register  ***
    SHARED VARIABLE SEC_reg        : std_logic_vector(23 downto 0)
                                            := (others => '0');

    SHARED VARIABLE WRAR_reg_in    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    SHARED VARIABLE RDAR_reg       : std_logic_vector(7 downto 0)
                                            := (others => '0');
    SIGNAL SBL_data_in             : std_logic_vector(7 downto 0)
                                            := (others => '0');

    SHARED VARIABLE ECC_reg        : std_logic_vector(7 downto 0)
                                            := (others => '0');
                                            
     SHARED VARIABLE MDID_reg       : std_logic_vector(127 downto 0)
                                            := x"FFFFFFFFFFFFFFFFFFFF90030F1B2B34";
                                      

    -- The Lock Protection Registers for OTP Memory space
    SHARED VARIABLE LOCK_BYTE1 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE2 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE3 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE4 :std_logic_vector(7 downto 0);
    
    SHARED VARIABLE DebugB           : NATURAL := 0;

    SHARED VARIABLE DIC_start_addr : NATURAL RANGE 0 TO AddrRANGE := 0;
    SHARED VARIABLE DIC_end_addr   : NATURAL RANGE 0 TO AddrRANGE := 0;
    SHARED VARIABLE dic_out        : std_logic_vector(31 downto 0) := (others => '0');

    SHARED VARIABLE SECSUSP    :INTEGER RANGE 0 TO SecNumHyb;

    SIGNAL Tseries     : NATURAL;
    SIGNAL Tcase       : NATURAL;

    SIGNAL count       : INTEGER RANGE -1 to 7 := -1;


    SIGNAL PARAMETER_ERASE    : BOOLEAN;

    SHARED VARIABLE ts_cnt  :   NATURAL RANGE 1 TO 42:=1; -- testseries counter
    SHARED VARIABLE tc_cnt  :   NATURAL RANGE 0 TO 15:=0; -- testcase counter

    FUNCTION ReturnAddr(ADDR : NATURAL; SADDR : NATURAL;
                        Arch: std_logic; Boot: std_logic; TopBottom: std_logic) RETURN NATURAL IS
        VARIABLE result : NATURAL;
    BEGIN
        IF (TopBottom = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top and Bottom
            IF (SADDR <= 16) THEN
                result := SADDR*(SecSize4+1) + ADDR;
            ELSE
                result := (SADDR-16)*(SecSize256+1) + ADDR;
            END IF;
        ELSIF (Arch = '0' AND Boot = '0') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF (SADDR <= 32) THEN
                result := SADDR*(SecSize4+1) + ADDR;
            ELSE
                result := (SADDR-32)*(SecSize256+1) + ADDR;
            END IF;
        ELSIF (Arch = '0' AND Boot = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF (SADDR <= 511) THEN
                result := SADDR*(SecSize256+1) + ADDR;
            ELSE
            result := AddrRANGE + 1 - 32*(SecSize4+1) +
                      (SADDR-512)*(SecSize4+1)+ ADDR;
            END IF;
        ELSE
        --Uniform Sector Architecture
            result := SADDR*(SecSize256+1) + ADDR;
        END IF;
        RETURN result;
    END ReturnAddr;

    PROCEDURE Sesa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL) IS
    BEGIN
        IF CFR1N(6) = '1' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SectorID <= 16 THEN
                IF SectorID < 16 AND PARAMETER_ERASE THEN
                    AddrLOW  := SectorID*(SecSize4+1);
                    AddrHIGH := SectorID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 16*(SecSize4+1);
                    AddrHIGH := SecSize256;
                END IF;
            ELSE
                AddrLOW  := (SectorID-16)*(SecSize256+1);
                AddrHIGH := (SectorID-16)*(SecSize256+1) + SecSize256;
            END IF;
        ELSIF CFR3V(3) = '0' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SectorID <= 32 THEN
                IF SectorID < 32 AND PARAMETER_ERASE THEN
                    AddrLOW  := SectorID*(SecSize4+1);
                    AddrHIGH := SectorID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 32*(SecSize4+1);
                    AddrHIGH := SecSize256;
                END IF;
            ELSE
                AddrLOW  := (SectorID-32)*(SecSize256+1);
                AddrHIGH := (SectorID-32)*(SecSize256+1) + SecSize256;
            END IF;
        ELSIF CFR3V(3) = '0' AND TBPARM_NV = '1' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF SectorID < 511 THEN
                AddrLOW  := SectorID*(SecSize256+1);
                AddrHIGH := SectorID*(SecSize256+1) + SecSize256;
            ELSE
                IF SectorID > 511 AND PARAMETER_ERASE THEN
                    AddrLOW  := AddrRANGE + 1 - 32*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1);
                    AddrHIGH := AddrRANGE + 1 - 32*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 511*(SecSize256+1);
                    AddrHIGH := AddrRANGE - 32*(SecSize4+1);
                END IF;
            END IF;
        ELSE
            AddrLOW  := SectorID*(SecSize256+1);
            AddrHIGH := SectorID*(SecSize256+1) + SecSize256;
        END IF;
    END Sesa;

    PROCEDURE sepa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL;
        VARIABLE   Addr     : NATURAL) IS
        VARIABLE   Page     : NATURAL;
        VARIABLE   Addr_tmp : NATURAL;
    BEGIN
        Addr_tmp := ReturnAddr(Addr,SectorID, CFR3V(3), TBPARM_NV, SPARM_NV);
        Page     := Addr_tmp/PageSize;-- page number

        AddrLOW  := Page*PageSize;
        AddrHIGH := Page*PageSize + PageSize - 1;

    END sepa;

    BEGIN
        DUT : s25hs01gt
        GENERIC MAP (

        -- memory file to be loaded
        mem_file_name   => "s25hs01gt.mem",
        otp_file_name   => "s25hs01gtOTP.mem",

        UserPreload     => UserPreload,

        -- For FMF SDF technology file usage
        TimingModel     => "S25HS01GTDSMHI010_30pF"
        )
        PORT MAP(
            SCK          => T_SCK,
            SI           => T_SI,
            SO           => T_SO,
            CSNeg        => T_CSNeg_mx,
            RESETNeg     => T_RESETNeg,
            IO3_RESETNeg => T_IO3RESETNeg,
            WPNeg        => T_WPNeg
        );

    Clock_polarity <= '0';--SPI mode: CPO L= 0, CPHA = 0
--     Clock_polarity <= '1';--SPI mode: CPO L= 1, CPHA = 1

    MODE <= DEFAULT_PROTECTION;
--    MODE <= PERSISTENT_PROTECTION;
--    MODE <= PASSWORD_PROTECTION;
--    MODE <= PASSWORD_PROTECTION_QPI;
--    MODE <= SEERC_READ;
--    MODE <= TEST_JEDEC_RESET;
--    MODE <= AUTOBOOT_TEST;
--    MODE <= PROGRAM_PPB_QPI;

    -- Multiplex T_CSNeg in order to generate JEDEC Reset and in order not to
    -- destroy other TB functionality
    T_CSNeg_mx <= T_CSNeg WHEN (jedec_reset_active = '0') ELSE T_CSNeg_jr;

    clk_count: PROCESS(T_SCK)
    BEGIN
        IF rising_edge(T_SCK) THEN
            count <= (count+1) mod 8;
        END IF;
    END PROCESS clk_count;

    clk_generation: PROCESS(T_SCK, T_CSNeg, CSNeg_flag, tcss_expired,
    tcssh_expired)
    BEGIN
        IF CSNeg_flag = '1' THEN
            T_SCK <= Clock_polarity;
        ELSIF NOT(DisableClock) THEN
            T_SCK <= NOT T_SCK AFTER half_period;
        END IF;
    END PROCESS clk_generation;

    max_time: PROCESS (T_CSNeg, T_SO)
    BEGIN
        IF ((ts_cnt = 1) AND (tc_cnt = 1)) THEN
            IF (rising_edge(T_CSNeg) AND (T_SO /= 'Z') AND (T_SO /= 'X')) THEN
                CSNEG_time := NOW;
            ELSIF ((T_CSNeg = '1') AND (T_SO = 'Z')) THEN
                SO_time := NOW - CSNEG_time;
            END IF;
            
            IF SO_time = 8 ns OR SO_time = 20 ns THEN
                sdf_max_param := TRUE;
--                sdf_max_param30 := TRUE;
            END IF;
            IF SO_time = 1.5 ns OR SO_time = 12 ns THEN
                sdf_min_param := TRUE;
            END IF;
            IF (TimingModel(19) = '1' AND (SO_time = 1.5 ns OR SO_time = 12 ns))  THEN
                   sdf_min_param15 := TRUE;
            ELSE
                   sdf_min_param15 := FALSE;
            END IF;
            IF (TimingModel(19) = '3' AND sdf_max_param = TRUE)  THEN
                   sdf_max_param30 := TRUE;
            ELSE
                   sdf_max_param30 := FALSE;
            END IF;
            IF (TimingModel(19) = '1' AND sdf_max_param = TRUE)  THEN
                   sdf_max_param15 := TRUE;
            ELSE
                   sdf_max_param15 := FALSE;
            END IF;
        END IF;
    END PROCESS max_time;

--At the end of the simulation, if ErrorInTest='0' there were no errors
    err_ctrl : PROCESS (check_err)
    BEGIN
        IF check_err = '1' THEN
            ErrorInTest <= '1';
        END IF;
    END PROCESS err_ctrl;

tb  :PROCESS

    --------------------------------------------------------------------------
    -- PROCEDURE to select TC
    -- can be modified to read TC list from file, or to generate random list
    --------------------------------------------------------------------------
    PROCEDURE   Pick_TC
        (Model   :  IN  string  := "s25hs01gt" )
    IS
    BEGIN
    CASE MODE IS
        WHEN DEFAULT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt < 33 THEN
                    TS_cnt := TS_cnt+1;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PERSISTENT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 31;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PASSWORD_PROTECTION   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 34;
                ELSIF TS_cnt = 34 THEN
                    TS_cnt := 35;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
        WHEN PASSWORD_PROTECTION_QPI   => 
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 41;
                ELSIF TS_cnt = 41 THEN
                    TS_cnt := 42;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
            
        WHEN SEERC_READ   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 36;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN TEST_JEDEC_RESET   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 37;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
         WHEN AUTOBOOT_TEST   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 38;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
        WHEN PROGRAM_PPB_QPI   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 39;
                ELSIF TS_cnt = 39 THEN
                    TS_cnt := 40;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
        END CASE;
    END PROCEDURE Pick_TC;

    ----------------------------------------------------------------------------
    --bus commands, device specific implementation
    ---------------------------------------------------------------------------

    TYPE bus_type IS (bus_idle,
                      bus_select,     --CS# asseretd
                      bus_select_no_clock,
                      bus_deselect,   --CS# deasserted after write
                      bus_deselect_no_clock,
                      bus_desel_read, --CS# deasserted after read
                      bus_opcode,
                      bus_reset,
					  bus_io3_reset,
                      bus_address,
                      bus_dummy_byte,
                      bus_dummy_clock,
                      bus_mode_byte,
                      bus_data_read,
                      bus_data_write,
                      bus_inv_write); -- write is less then 8 bits

    --bus drive for specific command sequence cycle
    PROCEDURE bus_cycle(
        bus_cmd   :IN   bus_type := bus_idle;
        opcode    :IN   std_logic_vector(7 downto 0) := "00000000";
        data4     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data3     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data2     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data1     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        address   :IN   NATURAL RANGE 0 TO AddrRANGE := 0;
        sector    :IN   INTEGER RANGE 0 TO SecNumHyb := 0;
        data_num  :IN   INTEGER RANGE 0 TO AddrRANGE := 0;
        protect   :IN   boolean                      := false;
        pulse     :IN   boolean                      := false;
        break     :IN   boolean                      := false;
        PowerUp   :IN   boolean                      := false;
        tm        :IN   TIME                         := 0 ns)
    IS
        VARIABLE tmpA         : std_logic_vector(31 downto 0);
        VARIABLE tmpD         : std_logic_vector(7 downto 0);
        VARIABLE tmpD1        : std_logic_vector(15 downto 0);
        VARIABLE tmpAB        : std_logic_vector(31 downto 0);
        VARIABLE tmpPASS      : std_logic_vector(63 downto 0);
        VARIABLE tmpDIC       : std_logic_vector(31 downto 0) := x"00000000";
        VARIABLE tmpData      : std_logic_vector(7 downto 0);
        VARIABLE Latency_code : NATURAL;
        VARIABLE Register_Latency : NATURAL;
        VARIABLE data_tmp4    : NATURAL := 0;
        VARIABLE data_tmp3    : NATURAL := 0;
        VARIABLE data_tmp2    : NATURAL := 0;
        VARIABLE data_tmp1    : NATURAL := 0;
        VARIABLE AddrLo       : NATURAL;
        VARIABLE AddrHi       : NATURAL;
        VARIABLE SECT         : NATURAL;

    BEGIN

        SECT := sector;


        tmpA := to_slv(ReturnAddr(address,SECT, CFR3V(3), TBPARM_NV, SPARM_NV));
        data_tmp4 := data4;
        data_tmp3 := data3;
        data_tmp2 := data2;
        data_tmp1 := data1;
        tmpD := to_slv(data_tmp1, 8);
        tmpD1:= to_slv(data_tmp1, 16);
        tmpAB(15 downto 0) := to_slv(data_tmp1, 16);
        tmpAB(31 downto 16):= to_slv(data_tmp2, 16);
        tmpPASS(63 downto 0):= to_slv(data_tmp4, 16)& to_slv(data_tmp3, 16)&
                               to_slv(data_tmp2, 16)& to_slv(data_tmp1, 16);

--         IF CFR2V(7) = '0' THEN
            tmpDIC := to_slv(address, 32);
--         END IF;

        CASE bus_cmd IS

            WHEN bus_idle        =>
                    MAX30 := '0';
--                     DisableClock  := TRUE;
                    CSNeg_flag <= '1';
                    WAIT FOR 3 ns;
                    T_CSNeg    <= '1';
                    T_CSNeg_jr    <= '1';
                    IF protect THEN
                        WAIT FOR 100 ns;
                        T_WPNeg <= not(T_WPNeg);
                    END IF;
                    WAIT FOR 20 ns;

            WHEN bus_select      =>
                DisableClock  := TRUE;
                tcss_expired  <= '0';
--                 tcssh_expired <= '0';
                T_CSNeg <= '0';
                CSNeg_flag <= '0';
                WAIT FOR tm;
                WAIT FOR tcss;
                DisableClock  := FALSE;
                tcss_expired  <= '1';
                
            WHEN bus_select_no_clock  =>
                DisableClock  := TRUE;
                tcss_expired  <= '0';
                tcssh_expired <= '0';
                T_CSNeg_jr    <= '0';
                WAIT FOR tm;
                WAIT FOR tcss;
                

            WHEN bus_reset  =>
                T_RESETNeg <= '0', '1' AFTER tm;
                WAIT FOR 30 ns;
			
			WHEN bus_io3_reset  =>
				T_IO3RESETNeg <= '0', '1' AFTER tm;
                WAIT FOR 30 ns;

            WHEN bus_inv_write        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                WAIT FOR 1.5 ns;
                FOR I IN 7 downto (data_num+1) LOOP
                    T_SI <= opcode(i);
                    WAIT FOR 2*half_period;
                END LOOP;
                T_SI <= opcode(data_num);

            WHEN bus_opcode        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                IF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
                    WAIT FOR 1.5 ns;
                ELSE
                    WAIT FOR 0.5 ns;
                END IF;
                IF (QPI = '0') THEN

                    FOR I IN 7 downto 1 LOOP
                        T_SI <= opcode(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= opcode(0);
                ELSE
                    T_IO3RESETNeg <= opcode(7);
                    T_WPNeg    <= opcode(6);
                    T_SO       <= opcode(5);
                    T_SI       <= opcode(4);
                    WAIT FOR 2*half_period;
                    T_IO3RESETNeg <= opcode(3);
                    T_WPNeg    <= opcode(2);
                    T_SO       <= opcode(1);
                    T_SI       <= opcode(0);
                END IF;
                -- if number of clock pulses isn't multiple of 8
                IF pulse THEN
                    WAIT FOR 2*half_period;
                END IF;
                IF (cmd = read_CR1 OR cmd = read_SR1 OR cmd = read_SR2
                    OR cmd = rd_dlp OR cmd = read_JID OR cmd = read_JQID
                    OR cmd = ppbl_reg_rd) AND QPI = '1' THEN 
                    WAIT FOR half_period;
                    WAIT FOR 4.75 ns;
                END IF;

            WHEN bus_deselect    =>
                WAIT UNTIL rising_edge(T_SCK);
                IF Clock_polarity = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                ELSE
                    WAIT FOR 3 ns;
                END IF;
--                 DisableClock  := TRUE;
                CSNeg_flag <= '1';
                WAIT FOR 3 ns;
                
                T_CSNeg <= '1';

                IF break THEN
                    WAIT FOR 15 ns;
                ELSE
                    WAIT FOR 30 ns;
                END IF;
                
            WHEN bus_deselect_no_clock  =>
--                 DisableClock  := TRUE;
                WAIT FOR tcssh;
                T_CSNeg_jr       <= '1';

                IF break THEN
                    WAIT FOR 15 ns;
                ELSE
                    WAIT FOR 30 ns;
                END IF;

            WHEN bus_desel_read    =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL rising_edge(T_SCK);
                    IF half_period = half_period1_srl THEN
                        WAIT FOR 3.5 ns;
                    ELSE
                        WAIT FOR 5 ns;
                    END IF;
                ELSE
                    IF half_period = half_period1_srl THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 2 ns;
                    ELSIF half_period = half_period_ddr THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    END IF;
                END IF;
                CSNeg_flag <= '1';
                WAIT FOR 3 ns;
                T_CSNeg <= '1';

                IF QUAD = '1' OR opcode = I_RESET THEN
                    WAIT FOR 2*half_period;
                    T_WPNeg    <= '1';
                    T_RESETNeg <= '1';
                END IF;

            WHEN bus_address     =>
               
                IF QPI = '1' THEN
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                    IF (opcode = I_DDRQIOR AND CFR2V(7) = '0') THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_IO3RESETNeg <= tmpA(23);
                            T_WPNeg    <= tmpA(22);
                            T_SO       <= tmpA(21);
                            T_SI       <= tmpA(20);
                            FOR I IN 4 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 5 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    ELSIF (opcode = I_DDRQIOR4 OR
                          (opcode = I_DDRQIOR AND CFR2V(7) = '1')) THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_IO3RESETNeg <= tmpA(31);
                            T_WPNeg    <= tmpA(30);
                            T_SO       <= tmpA(29);
                            T_SI       <= tmpA(28);
                            FOR I IN 6 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    --QUAD I/O High Performance (3 Bytes Address)
                    ELSIF opcode = I_RDQIOR AND CFR2V(7) = '0' THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 4 LOOP
                            T_IO3RESETNeg <= tmpA(23-4*i);
                            T_WPNeg    <= tmpA(22-4*i);
                            T_SO       <= tmpA(21-4*i);
                            T_SI       <= tmpA(20-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    --QUAD I/O High Performance (4 Bytes Address)
                    ELSIF (opcode = I_RDQIOR AND CFR2V(7) = '1') OR
                        opcode = I_RDQIOR4 THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 6 LOOP
                            T_IO3RESETNeg <= tmpA(31-4*i);
                            T_WPNeg    <= tmpA(30-4*i);
                            T_SO       <= tmpA(29-4*i);
                            T_SI       <= tmpA(28-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    ELSIF (opcode = I_RSFDP OR (CFR2V(7) = '0' AND
                      NOT(opcode = I_REDUS4 OR opcode = I_READ4 OR
                          opcode = I_FAST_READ4 OR opcode = I_DIOR4 OR
                          opcode = I_RDQIOR OR opcode = I_PP4 OR 
                          opcode = I_SE4 OR opcode = I_P4E4 OR
                          opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                          opcode = I_PPBRD4 OR opcode = I_PPBP4 OR
                          opcode = I_QOR4 OR opcode = I_DIC))) THEN
                    --3 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                            FOR I IN 0 TO 4 LOOP
                                T_IO3RESETNeg <= tmpA(23-4*i);
                                T_WPNeg    <= tmpA(22-4*i);
                                T_SO       <= tmpA(21-4*i);
                                T_SI       <= tmpA(20-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpA(3);
                            T_WPNeg    <= tmpA(2);
                            T_SO       <= tmpA(1);
                            T_SI       <= tmpA(0);
                    ELSE
                    --4 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        IF (opcode = I_DIC) THEN
                            FOR I IN 0 TO 6 LOOP
                                T_IO3RESETNeg <= tmpDIC(31-4*i);
                                T_WPNeg    <= tmpDIC(30-4*i);
                                T_SO       <= tmpDIC(29-4*i);
                                T_SI       <= tmpDIC(28-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpDIC(3);
                            T_WPNeg    <= tmpDIC(2);
                            T_SO       <= tmpDIC(1);
                            T_SI       <= tmpDIC(0);
                        ELSE
                            FOR I IN 0 TO 6 LOOP
                                T_IO3RESETNeg <= tmpA(31-4*i);
                                T_WPNeg    <= tmpA(30-4*i);
                                T_SO       <= tmpA(29-4*i);
                                T_SI       <= tmpA(28-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpA(3);
                            T_WPNeg    <= tmpA(2);
                            T_SO       <= tmpA(1);
                            T_SI       <= tmpA(0);
                        END IF;
                    END IF;
                --Dual I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_DIOR AND CFR2V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 10 LOOP
                        T_SO <= tmpA(23-2*i);
                        T_SI <= tmpA(22-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --Dual I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_DIOR AND CFR2V(7) = '1') OR
                       opcode = I_DIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 14 LOOP
                        T_SO <= tmpA(31-2*i);
                        T_SI <= tmpA(30-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --QUAD I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_RDQIOR AND CFR2V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 4 LOOP
                        T_IO3RESETNeg <= tmpA(23-4*i);
                        T_WPNeg    <= tmpA(22-4*i);
                        T_SO       <= tmpA(21-4*i);
                        T_SI       <= tmpA(20-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_IO3RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_RDQIOR AND CFR2V(7) = '1') OR
                       opcode = I_RDQIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 6 LOOP
                        T_IO3RESETNeg <= tmpA(31-4*i);
                        T_WPNeg    <= tmpA(30-4*i);
                        T_SO       <= tmpA(29-4*i);
                        T_SI       <= tmpA(28-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_IO3RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                ELSIF (opcode = I_DDRQIOR AND CFR2V(7) = '0') THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_IO3RESETNeg <= tmpA(23);
                        T_WPNeg    <= tmpA(22);
                        T_SO       <= tmpA(21);
                        T_SI       <= tmpA(20);
                        FOR I IN 4 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 5 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                ELSIF (opcode = I_DDRQIOR4 OR
                      (opcode = I_DDRQIOR AND CFR2V(7) = '1')) THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_IO3RESETNeg <= tmpA(31);
                        T_WPNeg    <= tmpA(30);
                        T_SO       <= tmpA(29);
                        T_SI       <= tmpA(28);
                        FOR I IN 6 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 7 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;

                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                --4 Bytes Address
                ELSIF opcode = I_QOR4 OR (opcode = I_QOR AND
                      CFR2V(7) = '1') THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSIF  opcode = I_QOR AND CFR2V(7) = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;

                    FOR I IN 23 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSIF opcode = I_FAST_READ4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
--                     WAIT FOR 3/4*half_period; 
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
 
--                     WAIT FOR 1.5 ns;
--                     IF status =  read_fast_4_IO THEN
--                         WAIT FOR 4 ns;
--                     END IF;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
   

                ELSIF opcode = I_READ4 OR 
                      opcode = I_PP4 OR opcode =I_SE4 OR opcode = I_P4E4 OR
                      opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                      opcode = I_PPBRD4 OR opcode = I_PPBP4 OR opcode = I_REDUS4 OR
                      ((opcode = I_READ OR opcode = I_FAST_READ OR opcode = I_OTPR OR
                      opcode = I_OTPP OR opcode = I_PP OR opcode = I_SE OR
                      opcode = I_P4E OR opcode = I_WRAR OR opcode = I_RDAR OR
                      opcode = I_DYBRD OR opcode = I_DYBWR OR opcode=I_REDUS OR
                      opcode = I_PPBRD OR opcode = I_PPBP OR opcode = I_EES OR 
                      opcode = I_SEERC) AND
                      CFR2V(7) = '1') THEN
--                       IF status =  read_fast_4_IO THEN
--                         WAIT FOR 2.2 ns;
--                     END IF;
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.7 ns;
--                     IF status =  read_fast_4_IO THEN
--                         WAIT FOR 4 ns;
--                     END IF;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSE  --3 Bytes Address
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;

                    FOR I IN 23 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                END IF;
                
           IF (cmd = dybacc_rd OR cmd = dybacc_rd4) AND QPI = '1' THEN 
                    WAIT FOR half_period;
                    WAIT FOR 4.25 ns;
                END IF;

            WHEN bus_mode_byte  =>
                IF QPI = '1' THEN
                    IF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 1.5 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    END IF;
                ELSIF opcode = I_FAST_READ4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;
                    FOR I IN 0 to 6 LOOP
                        T_SI <= tmpD(7-i);
--                         T_SI <= tmpD(6-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
--                     T_SO <= tmpD(1);
                    T_SI <= tmpD(0);
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.1 ns;
                    FOR I IN 0 to 2 LOOP
                        T_SO <= tmpD(7-2*i);
                        T_SI <= tmpD(6-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpD(1);
                    T_SI <= tmpD(0);
                ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.1 ns;
                    T_IO3RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR 2*half_period;
                    T_IO3RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                    WAIT UNTIL T_SCK'EVENT;
                    WAIT FOR 2 ns;
                    T_IO3RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR half_period;
                    T_IO3RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                END IF;

            WHEN bus_dummy_byte  =>
                IF opcode = I_RUID THEN
                    IF QPI = '1' THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 31 downto 1 LOOP
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 31 downto 1 LOOP
                            T_SI <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= 'Z';
                    END IF;
                ELSE
                    IF QPI = '1' THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_SI <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= 'Z';
                    END IF;
                END IF;

            WHEN bus_dummy_clock  =>
                IF opcode = I_RDSR1 OR opcode = I_RDID OR
                 (( opcode = I_RDSR2 OR opcode = I_RDCR1 OR opcode = I_DLPRD OR opcode = I_PLBRD) 
                  AND QPI = '0') OR
                 (( opcode = I_RDQID) AND QPI = '1') THEN
                 Register_Latency := to_nat(CFR3V(7)) + to_nat(CFR3V(7))*to_nat(CFR3V(6));
                 ELSIF (( opcode = I_RDSR2 OR opcode = I_RDCR1 OR opcode = I_DLPRD OR opcode = I_PLBRD) 
                  AND QPI = '1') OR opcode = I_RDAR OR opcode = I_DYBRD4 OR opcode = I_DYBRD THEN
                 Register_Latency := to_nat(CFR3V(7)) + to_nat(CFR3V(6));
                 END IF;
                Latency_code     := to_nat(CFR2V(3 DOWNTO 0));
--                 Register_Latency := to_nat(CFR3V(7 DOWNTO 6));

                IF QPI = '1' THEN
                    IF opcode = I_RDSR2 OR opcode = I_RDCR1 OR
                    opcode = I_PLBRD OR opcode = I_DLPRD THEN
                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_DYBRD OR opcode = I_DYBRD4 THEN
                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_PPBRD OR opcode = I_PPBRD4 THEN
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_RDSR1 OR opcode = I_RDID OR 
                    opcode = I_RDQID THEN

                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                DEBUG := 11;
                                WAIT FOR 1 ns;
                                DEBUG := 0;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_RDAR THEN
                        IF tmpA(24 downto 17) >= "00100000" THEN -- Volatile Regs
                            IF Register_Latency = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            ELSIF Register_Latency > 1 THEN
                                FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END IF;
                        ELSE -- Non-Volatile Regs
                            IF Latency_code = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            ELSIF Latency_code > 1 THEN
                                FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END IF;
                        END IF;
                    ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                           ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSE
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    END IF;
                ELSIF (opcode = I_DIOR OR opcode = I_DIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_DDRQIOR OR opcode = I_DDRQIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 2 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 0.1 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_RDQIOR OR opcode = I_RDQIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns; ----
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns; ----
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_QOR OR opcode = I_QOR4) THEN
                       IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF opcode = I_DYBRD OR opcode = I_DYBRD4 THEN
                    IF Register_Latency = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                    ELSIF Register_Latency > 1 THEN
                        FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                ELSIF  opcode = I_PPBRD OR opcode = I_PPBRD4 THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                ELSIF opcode = I_RDSR1 OR opcode = I_RDSR2 OR 
                      opcode = I_RDCR1 OR opcode = I_DLPRD OR
                      opcode = I_RDID OR opcode = I_PLBRD OR 
                      opcode = I_RDQID THEN
--                                                 DEBUG := 11;
--                                 WAIT FOR 1 ns;
--                                 DEBUG := 0;
                      T_SO       <= 'Z';  
                    IF Register_Latency = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        DEBUG := 11;
                                WAIT FOR 0.1 ns;
                                DEBUG := 0;
                        T_SI       <= 'Z';
                    ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                
                              DEBUG := 11;
                                WAIT FOR 0.1 ns;
                                DEBUG := 0;
                                T_SI       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_SI       <= 'Z';
                        
                        END IF;
                ELSIF opcode = I_RDAR THEN
                        IF tmpA(24 downto 17) >= "00100000" THEN -- Volatile Regs
                            IF Register_Latency = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_SI       <= 'Z';
                            ELSIF Register_Latency > 1 THEN
                                FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 0.1 ns;
                                T_SI       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_SI       <= 'Z';
                            END IF;
                        ELSE -- Non-Volatile Regs
                            IF Latency_code = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_SI       <= 'Z';
                            ELSIF Latency_code > 1 THEN
                                FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_SI       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_SI       <= 'Z';
                            END IF;
                        END IF;
                ELSE
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_SI       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                        
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                END IF;

            WHEN bus_data_read   =>
                IF QPI = '1' OR opcode = I_RDQIOR OR opcode = I_RDQIOR4 OR
                opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 OR
                opcode = I_RDQID THEN
                    WAIT FOR 6.5 ns;
                    
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_IO3RESETNeg <= 'Z';
                    MAX30 := '1';
                ELSIF opcode = I_QOR OR opcode = I_QOR4  THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_IO3RESETNeg <= 'Z';
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                ELSIF opcode = I_FAST_READ4 THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                ELSE
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                END IF;
                IF break THEN
                    FOR I IN data_num-1 downto 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 8 ns;
                    END LOOP;
                ELSE
                    IF opcode = I_FAST_READ4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 8 ns;
  
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                        MAX30 := '1';
                    ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        FOR I IN data_num DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 4 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF ((QPI = '1') AND (opcode = I_RDSR1)) THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                DEBUG := 11;
                                WAIT FOR 3 ns;
                                DEBUG := 0;
                            END LOOP;
                        END LOOP;
                        IF sdf_max_param THEN
                        WAIT FOR  3 ns ;
                        END IF;
                    
                    ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 3 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                           END LOOP;
                       END LOOP;
                   ELSIF opcode = I_QOR OR opcode = I_QOR4 THEN
                       FOR I IN data_num-1 DOWNTO 0 LOOP
                           FOR I IN 1 downto 0 LOOP
                               WAIT UNTIL falling_edge(T_SCK);
                               WAIT FOR 5.8 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF QPI = '1' THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 8 ns;
                            END LOOP;
                        END LOOP;
                    ELSE
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                IF half_period = half_period1_srl THEN
                                    WAIT FOR 3 ns;
                                ELSE
--                                    DebugB := 3;
                                    WAIT FOR 7 ns;
--                                    DebugB := 0;
                                END IF;
                            END LOOP;
                        END LOOP;
                    END IF;
                END IF;
                --two more bit of data-out sequence
                IF pulse THEN
                    WAIT FOR 4*half_period;
                ELSIF QUAD = '1' THEN
                   WAIT FOR half_period;
                END IF;

            WHEN bus_data_write  =>
                IF cmd = w_autoboot AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 0 to 6 LOOP
--                         T_SI <= tmpAB(i);
                        T_IO3RESETNeg <= tmpAB(31 - I*4);
                        T_WPNeg    <= tmpAB(30 - I*4);
                        T_SO       <= tmpAB(29 - I*4);
                        T_SI       <= tmpAB(28 - I*4);
                        WAIT FOR 2*half_period;
                    END LOOP;
                        T_IO3RESETNeg <= tmpAB(3);
                        T_WPNeg    <= tmpAB(2);
                        T_SO       <= tmpAB(1);
                        T_SI       <= tmpAB(0);
                    tmpAB := AutoBoot_reg;
--                     tmpAB := to_slv(data_tmp2, 16)&to_slv(data_tmp1, 16);
--                      AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
--                   slv_4(7 downto 0) & slv_4(15 downto 8);
                 ELSIF cmd = w_asp AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;

                        T_IO3RESETNeg <= tmpD1(7);
                        T_WPNeg    <=    tmpD1(6);
                        T_SO       <=    tmpD1(5);
                        T_SI       <=    tmpD1(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD1(3);
                        T_WPNeg    <=    tmpD1(2);
                        T_SO       <=    tmpD1(1);
                        T_SI       <=    tmpD1(0);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD1(15);
                        T_WPNeg    <=    tmpD1(14);
                        T_SO       <=    tmpD1(13);
                        T_SI       <=    tmpD1(12);
                        WAIT FOR 2*half_period;
 
                    T_IO3RESETNeg <= tmpD1(11);
                        T_WPNeg    <=    tmpD1(10);
                        T_SO       <=    tmpD1(9);
                        T_SI       <=    tmpD1(8);
                    tmpD1 := to_slv(data_tmp1, 16);
                ELSIF (cmd = w_password OR cmd = psw_unlock) AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 1 to 7 LOOP
                            T_IO3RESETNeg <= tmpPASS(I*8-1);
                            T_WPNeg    <=    tmpPASS(I*8-2);
                            T_SO       <=    tmpPASS(I*8-3);
                            T_SI       <=    tmpPASS(I*8-4);
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= tmpPASS(I*8-5);
                            T_WPNeg    <=    tmpPASS(I*8-6);
                            T_SO       <=    tmpPASS(I*8-7);
                            T_SI       <=    tmpPASS(I*8-8);
                            WAIT FOR 2*half_period;
                    END LOOP;
                            T_IO3RESETNeg <= tmpPASS(63);
                            T_WPNeg    <=    tmpPASS(62);
                            T_SO       <=    tmpPASS(61);
                            T_SI       <=    tmpPASS(60);
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= tmpPASS(59);
                            T_WPNeg    <=    tmpPASS(58);
                            T_SO       <=    tmpPASS(57);
                            T_SI       <=    tmpPASS(56);
                ELSIF QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                        IF I > 0 THEN
                            WAIT FOR 2*half_period;
                        END IF;
                    END LOOP;
               
                ELSIF cmd = w_scr OR cmd = w_asp THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 15 downto 1 LOOP
                        T_SI <= tmpD1(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpD1(0);
                    tmpD1 := to_slv(data_tmp1, 16);
                ELSIF cmd = w_autoboot AND QPI = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpAB(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpAB(0);
--                     AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
--                                     slv_4(7 downto 0) & slv_4(15 downto 8);
--                     tmpAB := to_slv(data_tmp2, 16)&to_slv(data_tmp1, 16);
                    tmpAB := AutoBoot_reg;
                 
                ELSIF cmd = w_password OR cmd = psw_unlock THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 1 to 7 LOOP
                        FOR J IN 1 to 8 LOOP
                            T_SI <= tmpPASS(I*8-J);
                            WAIT FOR 2*half_period;
                        END LOOP;
                    END LOOP;
                    FOR J IN 1 to 7 LOOP
                        T_SI <= tmpPASS(64-J);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpPASS(56);
               ELSIF cmd = read_JQID OR cmd = quad_rd THEN
                   FOR I IN data_num-1 DOWNTO 0 LOOP
                       WAIT UNTIL falling_edge(T_SCK);
                       WAIT FOR 2 ns;
                       FOR I IN 7 downto 1 LOOP
                           T_SI <= tmpD(i);
                           WAIT FOR 2*half_period;
                       END LOOP;
                       T_SI <= tmpD(0);
                       data_tmp1 := data_tmp1 + 1;
                       tmpD := to_slv(data_tmp1, 8);
                   END LOOP;
                ELSE
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_SI <= tmpD(i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                    END LOOP;
                END IF;

        END CASE;

    END PROCEDURE;

   ----------------------------------------------------------------------------
    --procedure to decode commands into specific bus command sequence
    ---------------------------------------------------------------------------
    PROCEDURE cmd_dc
        (   command  :   IN  cmd_rec   )

    IS

        VARIABLE slv_1, slv_2 : std_logic_vector(7 downto 0);
        VARIABLE slv_3, slv_4 : std_logic_vector(15 downto 0);
        VARIABLE opcode_tmp   : std_logic_vector(7 downto 0);
        VARIABLE Data_byte    : INTEGER RANGE 0 TO 16#FFFF#  := 0;
        VARIABLE Byte_number  : NATURAL RANGE 0 TO 600;
        VARIABLE cnt          : NATURAL RANGE 0 TO 512;
        VARIABLE pgm_page     : NATURAL;
        VARIABLE page_addr    : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrLow      : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE ADDR         : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE ADDR_LOW     : NATURAL;
        VARIABLE ADDR_HIGH    : NATURAL;
        VARIABLE addr_tmp     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrHigh     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE SECTOR       : NATURAL RANGE 0 TO 543;
        VARIABLE BP_bits      : std_logic_vector(2 downto 0) := "000";
        VARIABLE tm           : TIME                         := 0 ns;
        VARIABLE tmp          : NATURAL;
        VARIABLE tmp_byte_num : NATURAL;
        VARIABLE pass_tmp     : std_logic_vector(63 downto 0);
        VARIABLE sec_tmp      : NATURAL RANGE 0 TO 543;
        VARIABLE Bank_Addr_reg_tmp: std_logic_vector(7 downto 0)
                                            := (others => '0');
        VARIABLE dic_tmp      : std_logic;
    BEGIN

        half_period := half_period1_srl;

        CASE command.cmd IS

            WHEN    idle        =>

                bus_cycle(bus_cmd => bus_idle,
                          PowerUp => command.aux=PowerUp,
                          protect => command.aux=violate);

            WHEN    w_enable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WREN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '1';
                END IF;

                WAIT FOR 9*half_period ;
            
            WHEN    w_wrenv    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRENV,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WVREG := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    w_disable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRDI,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '0';
                    WVREG := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    reset_en    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSTEN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                WAIT FOR 9*half_period ;

            WHEN    rst    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RST,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                    STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                    CFR1V(7 DOWNTO 1) := CFR1N(7 DOWNTO 1);

                    CFR2V := CFR2N;
                    CFR3V := CFR3N;
                    CFR4V := CFR4N;

                    VDLR_reg  := NVDLR_reg;

                    IF CFR3V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                        BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-19)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-20)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(19 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-20))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                               ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-23)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-24)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(23 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-24))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-32)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(31 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-32))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-47)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-48)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(47 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-48))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-79)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-80)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(79 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-80))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-143)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-144)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(143 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-144))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                END IF;
                WAIT for 50 ns;

            WHEN    reset_cmd    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RESET,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                    STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                    CFR1V(7 DOWNTO 1) := CFR1N(7 DOWNTO 1);

                    CFR2V := CFR2N;
                    CFR3V := CFR3N;
                    CFR4V := CFR4N;

                    VDLR_reg  := NVDLR_reg;

                    IF CFR3V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                        BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                END IF;
                WAIT for 50 ns;
                
             WHEN    bax4   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EX4BA_0_0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    CFR2V(7) := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    bam4   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BAM4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    CFR2V(7) := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    ees   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EES,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_EES,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status = chk_sts_1 THEN
                    STR2V(2) := '1';
                ELSIF status = chk_sts_0 THEN
                    STR2V(2) := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    set_bl   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_SBL,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_SBL,
                          data_num => command.byte_num,
                          data1    => command.data1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    Data_byte :=  command.data1;
                    slv_1 := to_slv(Data_byte,8);
                    CFR4V(4)          := slv_1(4);
                    CFR4V(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    h_reset         =>

                bus_cycle(bus_cmd => bus_reset,
                          data_num=> 1,
                          tm      => command.wtime);

                STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                CFR1V := CFR1N;
                CFR2V := CFR2N;
                CFR3V := CFR3N;
                CFR4V := CFR4N;

                IF CFR3V(4) = '1' THEN
                    PageSize <= 512;
                    PageNum <= PageNum512;
                ELSE
                    PageSize <= 256;
                    PageNum <= PageNum256;
                END IF;

                VDLR_reg  := NVDLR_reg;

                IF PWDMLB = '0' THEN
                    PPB_LOCK := '0';
                ELSE
                    PPB_LOCK := '1';
                END IF;

                STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                CASE BP_bits IS

                    WHEN "000" =>
                        Sec_Prot := (OTHERS => '0');

                    WHEN "001" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*63/64)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/64)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "010" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN--BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*31/32)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/32)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "011" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*15/16)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/16)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "100" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*7/8)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/8)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "101" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*3/4)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/4)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "110" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN  --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        Sec_Prot := (OTHERS => '1');
                END CASE;

                WAIT for 50 ns;

            WHEN    h_io3_reset         =>  --Naim add for IO3_RESETNeg hardware reset

                bus_cycle(bus_cmd => bus_io3_reset,
                          data_num=> 1,
                          tm      => command.wtime);

                STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                CFR1V := CFR1N;
                CFR2V := CFR2N;
                CFR3V := CFR3N;
                CFR4V := CFR4N;

                IF CFR3V(4) = '1' THEN
                    PageSize <= 512;
                    PageNum <= PageNum512;
                ELSE
                    PageSize <= 256;
                    PageNum <= PageNum256;
                END IF;

                VDLR_reg  := NVDLR_reg;

                IF PWDMLB = '0' THEN
                    PPB_LOCK := '0';
                ELSE
                    PPB_LOCK := '1';
                END IF;

                STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                CASE BP_bits IS

                    WHEN "000" =>
                        Sec_Prot := (OTHERS => '0');

                    WHEN "001" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*63/64)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/64)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "010" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN--BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*31/32)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/32)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "011" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*15/16)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/16)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "100" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*7/8)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/8)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "101" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*3/4)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/4)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "110" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN  --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        Sec_Prot := (OTHERS => '1');
                END CASE;

                WAIT for 50 ns;
			
			WHEN    w_sr         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);
                WIP := '1';

                IF status /= err AND WEL = '1' THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN

                        SRWD_NV   := slv_1 (7);
                        SRWD      := slv_1 (7);

                        IF (LOCK_O='0') THEN
                            IF FREEZE ='0' THEN

                                    BP2_NV := slv_1 (4);
                                    BP1_NV := slv_1 (3);
                                    BP0_NV := slv_1 (2);

                                    BP2    := slv_1 (4);
                                    BP1    := slv_1 (3);
                                    BP0    := slv_1 (2);
  

                                BP_bits := BP2 & BP1 & BP0;
                            END IF;
                        END IF;

                        Sec_Prot := (others => '0');
                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    wrar         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRAR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_WRAR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                SECTOR := command.sect;
                ADDR   := command.addr;
                addr_tmp := ReturnAddr(ADDR,SECTOR, CFR3V(3), TBPARM_NV, SPARM_NV);

                Data_byte :=  command.data1;
                slv_1     := to_slv(Data_byte,8);
                WIP       := '1';

                IF status /= err AND (WEL = '1' OR (WVREG = '1'  AND  addr_tmp >= 16#00800000#)) THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN
                        IF addr_tmp = 16#00000000# THEN
                            SRWD_NV   := slv_1 (7);
                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0') THEN
                                IF FREEZE ='0' THEN
 
                                        BP2_NV := slv_1 (4);
                                        BP1_NV := slv_1 (3);
                                        BP0_NV := slv_1 (2);

                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
     

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            Sec_Prot := (others => '0');
                            CASE BP_bits IS

                                WHEN "000" =>
                                    Sec_Prot := (OTHERS => '0');

                                WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN OTHERS =>
                                    Sec_Prot := (OTHERS => '1');
                            END CASE;

                        ELSIF addr_tmp = 16#00000002# THEN
                            IF TBPROT_NV = '0' THEN
                                TBPROT_NV  := slv_1 (5);
                                TBPROT    := slv_1 (5);
                            END IF;

       

                            IF (TBPARM_NV = '0' AND CFR3V(3) = '0') THEN
                                TBPARM_NV  := slv_1 (2);
                                TBPARM    := slv_1 (2);
                            END IF;

--                             IF QPI = '0' THEN
                                QUAD_NV := slv_1(1);
                                QUAD    := slv_1(1);
--                             END IF;
                            
                            IF FREEZE = '0' THEN
                                FREEZE    := slv_1(0);
                            END IF;

                            IF LOCK_O = '0' THEN
                                LOCK_O  := slv_1(4);
                                LOCK    := slv_1(4);
                            END IF;
                        ELSIF addr_tmp = 16#00000003# THEN

                            IF CFR2N(7) = '0' THEN
                                CFR2N(7) := slv_1(7);
                                CFR2V(7)  := slv_1(7);
                            END IF;

                            IF CFR2N(6) = '0'  AND slv_1(6) = '1' THEN
                                CFR2N(6) := slv_1(6);
                                QPI    := slv_1(6);

--                                 QUAD_NV := '1';
--                                 QUAD    := '1';
                            END IF;

                            IF CFR2N(5) = '0' THEN
                                CFR2N(5) := slv_1(5);
                                CFR2V(5)  := slv_1(5);
                            END IF;

                            IF CFR2N(3 DOWNTO 0) = "1000" THEN
                                CFR2N(3 DOWNTO 0) := slv_1(3 DOWNTO 0);
                                CFR2V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000004# THEN
                        
                                CFR3N(7) := slv_1(7);
                                CFR3V(7)  := slv_1(7);

                                CFR3N(6) := slv_1(6);
                                CFR3V(6)  := slv_1(6);

                            IF CFR3N(5) = '0' THEN
                                CFR3N(5) := slv_1(5);
                                CFR3V(5)  := slv_1(5);
                            END IF;

                            IF CFR3N(4) = '0' THEN
                                CFR3N(4) := slv_1(4);
                                CFR3V(4)  := slv_1(4);
                            END IF;

                            IF CFR3N(3) = '0' THEN
                                CFR3N(3) := slv_1(3);
                                CFR3V(3)  := slv_1(3);
                            END IF;

                            IF CFR3N(2) = '0' THEN
                                CFR3N(2) := slv_1(2);
                                CFR3V(2)  := slv_1(2);
                            END IF;

                            IF CFR3N(0) = '0' THEN
                                CFR3N(0) := slv_1(0);
                                CFR3V(0)  := slv_1(0);
                            END IF;

                            IF CFR3V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00000005# THEN

                            IF CFR4N(7 DOWNTO 5) = "000" THEN
                                CFR4N(7 DOWNTO 5) := slv_1(7 DOWNTO 5);
                                CFR4V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            END IF;

                            IF CFR4N(4) = '0' THEN
                                CFR4N(4) := slv_1(4);
                                CFR4V(4)  := slv_1(4);
                            END IF;

                            IF CFR4N(1 DOWNTO 0) = "00" THEN
                                CFR4N(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                                CFR4V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            IF to_nat(NVDLR_reg) > -1 THEN
                                slv_2 := NVDLR_reg;
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                                NVDLR_reg := slv_1;
                                VDLR_reg  := slv_1;
                            END IF;

                        ELSIF addr_tmp = 16#00000020# THEN
                            Password_reg(7 DOWNTO 0) := slv_1;
                        ELSIF addr_tmp = 16#00000021# THEN
                            Password_reg(15 DOWNTO 8) := slv_1;
                        ELSIF addr_tmp = 16#00000022# THEN
                            Password_reg(23 DOWNTO 16) := slv_1;
                        ELSIF addr_tmp = 16#00000023# THEN
                            Password_reg(31 DOWNTO 24) := slv_1;
                        ELSIF addr_tmp = 16#00000024# THEN
                            Password_reg(39 DOWNTO 32) := slv_1;
                        ELSIF addr_tmp = 16#00000025# THEN
                            Password_reg(47 DOWNTO 40) := slv_1;
                        ELSIF addr_tmp = 16#00000026# THEN
                            Password_reg(55 DOWNTO 48) := slv_1;
                        ELSIF addr_tmp = 16#00000027# THEN
                            Password_reg(63 DOWNTO 56) := slv_1;
                        ELSIF addr_tmp = 16#00000030# THEN

                            IF DYBLBB = '1' THEN
                                DYBLBB := slv_1(4);
                            END IF;

                            IF PPBOTP = '1' THEN
                                PPBOTP    := slv_1(3);
                            END IF;

                            IF PERMLB = '1' THEN
                                PERMLB    := slv_1(0);
                            END IF;

                            IF (slv_1(2) = '0' AND slv_1(1) = '0') THEN
                                P_ERR := '1';
                                WIP   := '1';
                            ELSE
                                PWDMLB    := slv_1(2);
                                PSTMLB    := slv_1(1);
                            END IF;

                        ELSIF addr_tmp = 16#00800000# THEN

                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0') THEN
                                IF FREEZE ='0' THEN
  
                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
        

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            Sec_Prot := (others => '0');
                            CASE BP_bits IS

                                WHEN "000" =>
                                    Sec_Prot := (OTHERS => '0');

                                WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN OTHERS =>
                                    Sec_Prot := (OTHERS => '1');
                            END CASE;

                        ELSIF addr_tmp = 16#00800002# THEN

--                             IF QPI = '0' THEN
                                QUAD    := slv_1(1);
--                             END IF;

                            IF FREEZE = '0' THEN
                                FREEZE    := slv_1(0);
                            END IF;

                        ELSIF addr_tmp = 16#00800003# THEN

                            CFR2V(7)  := slv_1(7);
                            QPI    := slv_1(6);
--                             IF slv_1(6) = '1' THEN
--                                 QUAD    := '1';
-- --                             END IF;
                            CFR2V(5)  := slv_1(5);
                            CFR2V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800004# THEN
                        
                             
                            CFR3V(7)  := slv_1(7);
                            CFR3V(6)  := slv_1(6);

                            CFR3V(5)  := slv_1(5);
                            CFR3V(4)  := slv_1(4);
                            CFR3V(3)  := slv_1(3);
                            CFR3V(2)  := slv_1(2);
                            CFR3V(0)  := slv_1(0);

                            IF CFR3V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00800005# THEN

                            CFR4V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            CFR4V(4)           := slv_1(4);
                            CFR4V(3)           := slv_1(3);
                            CFR4V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            VDLR_reg  := slv_1;
                        END IF;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    rdar_read       =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_RDAR,
                          pulse    => false,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_address,
                          opcode   => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_read,
                          opcode   => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          data_num => command.byte_num,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_CR1 =>

                half_period := half_period2_srl;

                IF command.cmd = read_CR1 THEN
                    opcode_tmp      := I_RDCR1;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => opcode_tmp,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => opcode_tmp,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SR1       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR1,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDSR1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR1,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SR2       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR2,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDSR2,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR2,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    clr_sr       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_CLSR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN
                    E_ERR := '0';
                    P_ERR := '0';
                    WIP   := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_scr        =>

                WIP := '1';
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_WRR,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                Data_byte :=  command.data1;
                slv_3 := to_slv(Data_byte,16);

                WAIT FOR 22*half_period ;

                IF status /= err AND WEL = '1'  THEN
                        IF NOT(SRWD = '1' AND T_WPNeg='0') OR (QUAD = '1' OR QPI = '1') THEN

                        SRWD_NV   := slv_3 (15);
                        SRWD      := slv_3 (15);

                        IF (LOCK_O='0' ) THEN
                            IF FREEZE ='0' THEN
 
                                    BP2_NV := slv_3 (12);
                                    BP1_NV := slv_3 (11);
                                    BP0_NV := slv_3 (10);

                                    BP2    := slv_3 (12);
                                    BP1    := slv_3 (11);
                                    BP0    := slv_3 (10);
   

                                BP_bits := BP2 & BP1 & BP0;

--                                 IF TBPROT_NV = '0' THEN
                                    TBPROT_NV  := slv_3 (5);
--                                     TBPROT    := slv_3 (5);
--                                 END IF;


--                                 IF (TBPARM_NV = '0' AND CFR3V(3) = '0') THEN
                                    TBPARM_NV  := slv_3 (2);
--                                     TBPARM    := slv_3 (2);
--                                 END IF;
                            END IF;
                        END IF;

--                         IF QPI = '0' THEN
                            QUAD_NV := slv_3(1);
                            QUAD    := slv_3(1);
--                         END IF;

                        IF FREEZE = '0' THEN
                            FREEZE    := slv_3(0);
                        END IF;

                        IF LOCK_O = '0' THEN
                            LOCK_O  := slv_3(4);
--                             LOCK    := slv_3(4);
                        END IF;

                        Sec_Prot := (others => '0');
                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    w_dic  =>

                    ADDR_LOW  := to_nat(to_slv(command.data4, 16) & to_slv(command.data3,16));
                    ADDR_HIGH := to_nat(to_slv(command.data2, 16) & to_slv(command.data1,16));

                
                IF command.cmd = w_dic THEN
                    opcode_tmp      := I_DIC;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => ADDR_LOW,
                          tm      => command.wtime);
                          
                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => ADDR_HIGH,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                -- DIC start address 
                dic_out := (others => '0');
                FOR I IN ADDR_LOW TO ADDR_HIGH LOOP
                    slv_3 := to_slv(mem(I),16);
                    FOR J IN 15 DOWNTO 0 LOOP
                        dic_tmp := dic_out(31) XOR slv_3(J);
                        dic_out(31) := dic_out(30);
                        dic_out(30) := dic_out(29);
                        dic_out(29) := dic_out(28);
                        dic_out(28) := dic_out(27) XOR dic_tmp;
                        dic_out(27) := dic_out(26) XOR dic_tmp;
                        dic_out(26) := dic_out(25) XOR dic_tmp;
                        dic_out(25) := dic_out(24) XOR dic_tmp;
                        dic_out(24) := dic_out(23);
                        dic_out(23) := dic_out(22) XOR dic_tmp;
                        dic_out(22) := dic_out(21) XOR dic_tmp;
                        dic_out(21) := dic_out(20);
                        dic_out(20) := dic_out(19) XOR dic_tmp;
                        dic_out(19) := dic_out(18) XOR dic_tmp;
                        dic_out(18) := dic_out(17) XOR dic_tmp;
                        dic_out(17) := dic_out(16);
                        dic_out(16) := dic_out(15);
                        dic_out(15) := dic_out(14);
                        dic_out(14) := dic_out(13) XOR dic_tmp;
                        dic_out(13) := dic_out(12) XOR dic_tmp;
                        dic_out(12) := dic_out(11);
                        dic_out(11) := dic_out(10) XOR dic_tmp;
                        dic_out(10) := dic_out(9) XOR dic_tmp;
                        dic_out(9) := dic_out(8) XOR dic_tmp;
                        dic_out(8) := dic_out(7) XOR dic_tmp;
                        dic_out(7) := dic_out(6);
                        dic_out(6) := dic_out(5) XOR dic_tmp;
                        dic_out(5) := dic_out(4);
                        dic_out(4) := dic_out(3);
                        dic_out(3) := dic_out(2);
                        dic_out(2) := dic_out(1);
                        dic_out(1) := dic_out(0);
                        dic_out(0) :=  dic_tmp;
                    END LOOP;
                END LOOP;
                DIC_reg := dic_out;
                WAIT FOR 10*half_period ;
            WHEN    rd_dlp       =>
            
            
--                IF sdf_max_param30 = TRUE THEN
--                     half_period := half_period_30pF;
--                ELSE
                    half_period := half_period2_srl;
--                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DLPRD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DLPRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DLPRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    rd_4           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ4,
                          data1   => command.data1,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    fast_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    fast_rd4       =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);
                
                IF command.status /= read_fast_4_IO THEN

                          bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ4,
                          pulse   => false,
                          tm      => command.wtime);
                END IF;

                

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);
                          
                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_FAST_READ4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;
--                  IF command.aux = break THEN
--                     WAIT FOR 4*half_period;
--                 END IF;
                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_FAST_READ4);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd_4      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR4,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    quad_rd      =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_QOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_QOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_QOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_QOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_QOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_rd_4      =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_QOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_QOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_QOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_QOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_QOR4);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd_4      =>
            
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 102 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd_4      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 102 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    read_JID       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    read_JQID       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDQID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;
                
             WHEN    read_RUID      =>
             
                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RUID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_RUID,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RUID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SFDP      =>
                
                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSFDP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RSFDP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_RSFDP,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RSFDP,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);
                
--                  data_num=> (SFDPHiAddr+1 - command.addr)/2,

                WAIT FOR 22*half_period ;

            WHEN    sector_erase  | p4_erase =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                IF command.cmd = sector_erase THEN
                    opcode_tmp      := I_SE;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase THEN
                    opcode_tmp      := I_P4E;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);
                        FOR i IN AddrLow TO AddrHigh LOOP
                            mem(i) := 16#FF#;
                        END LOOP;
                        E_ERR := '0';
                        WEL := '0';
                        WIP := '0';
                        WVREG := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                    WVREG := '0';
                END IF;

            WHEN    sector_erase_4  | p4_erase_4  =>

                SECTOR := command.sect;
                ADDR := command.addr;

                IF command.cmd = sector_erase_4 THEN
                    opcode_tmp      := I_SE4;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase_4 THEN
                    opcode_tmp      := I_P4E4;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);
                        FOR i IN AddrLow TO AddrHigh LOOP
                            mem(i) := 16#FF#;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                    WVREG := '0';
                END IF;

            WHEN    bulk_erase_60 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_60,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CFR3V(3) = '0' THEN
                                sec_tmp := i / (SecSize256+1);
                                IF TBPARM_NV = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (32*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 32;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 32;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            32*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 32*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize256+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN
                                mem(i) := 16#FF#;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WVREG := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN    bulk_erase_C7 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_C7,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CFR3V(3) = '0' THEN
                                sec_tmp := i / (SecSize256+1);
                                IF TBPARM_NV = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (32*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 32;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 32;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            32*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 32*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize256+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN
                                mem(i) := 16#FF#;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WVREG := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN     ers_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN     ers_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN    csneg_zero   =>

                bus_cycle(bus_cmd => bus_select);

                WAIT FOR command.wtime;

                bus_cycle(bus_cmd => bus_deselect);

            WHEN     dp_down    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DPD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

            WHEN    pg_prog      =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CFR3V(3),TBPARM_NV, SPARM_NV);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);

                            IF mem(page_addr+i-cnt)>-1 THEN
                                slv_2 := to_slv(mem(page_addr+i-cnt),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            mem(page_addr + i - cnt) := to_nat(slv_1);

                            IF page_addr + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                page_addr := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        IF ES = '0' THEN
                            WEL := '0';
                            WVREG := '0';
                        END IF;
                        WIP := '0';
                    ELSE
                        P_ERR := '1';
                        WIP := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    pg_prog4      =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP4,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CFR3V(3),TBPARM_NV, SPARM_NV);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);

                            IF mem(page_addr+i-cnt)>-1 THEN
                                slv_2 := to_slv(mem(page_addr+i-cnt),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            mem(page_addr + i - cnt) := to_nat(slv_1);

                            IF page_addr + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                page_addr := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN     prg_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN     prg_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN    otp_prog      =>

                ADDR        := command.addr;
                Data_byte   := command.data1;
                Byte_number := command.byte_num;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPP,
                          address => command.addr,
                          sector  => 0,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_OTPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                LOCK_BYTE1 := to_slv(Otp(16#10#),8);
                LOCK_BYTE2 := to_slv(Otp(16#11#),8);
                LOCK_BYTE3 := to_slv(Otp(16#12#),8);
                LOCK_BYTE4 := to_slv(Otp(16#13#),8);

                IF status /= err AND WEL = '1' AND FREEZE = '0' THEN
                    WIP := '1';
                    IF ADDR + (Byte_number - 1) <= OTPHiAddr THEN
                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            slv_1 := to_slv(Data_byte,8);

                            IF Otp(ADDR + i)>-1 THEN
                                slv_2 := to_slv(Otp(ADDR + i),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            Otp(ADDR + i) := to_nat(slv_1);

                            IF Data_byte = 255 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                    ELSE
                        ASSERT false
                            REPORT "Programming will reach over address "&
                            " limit of OTP array"
                            SEVERITY warning;
                    END IF;
                    P_ERR := '0';
                    WEL   := '0';
                    WVREG := '0';
                    WIP   := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

            WHEN    otp_read      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;
                
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_OTPR,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_OTPR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_nvldr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_PNVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_PNVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    IF to_nat(NVDLR_reg) > -1 THEN
                        slv_2 := NVDLR_reg;
                    ELSE
                        slv_2 := (OTHERS=>'X');
                    END IF;

                    IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                        NVDLR_reg := slv_1;
                        VDLR_reg  := slv_1;
                    END IF;

                    WEL := '0';
                    WVREG := '0';
--                     VDLR_reg  := NVDLR_reg; --???
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_wvdlr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_WVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_WVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    VDLR_reg  := slv_1;
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_autoboot      =>

                WIP := '1';
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ABWR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_ABWR,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                slv_3 := to_slv(command.data1, 16);
                slv_4 := to_slv(command.data2, 16);

                IF status /= err AND WEL = '1' THEN
                    AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
                                    slv_4(7 downto 0) & slv_4(15 downto 8);

                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_asp      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ASPP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_ASPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' AND (PWDMLB = '1' AND
                   PSTMLB = '1') THEN

                    slv_3 := to_slv(command.data1, 16);

                    IF DYBLBB = '1' THEN
                        DYBLBB := slv_3(4);
                    END IF;

                    IF PPBOTP = '1' THEN
                        PPBOTP    := slv_3(3);
                    END IF;

                    IF PERMLB = '1' THEN
                        PERMLB    := slv_3(0);
                    END IF;

                    IF (slv_3(2) = '0' AND slv_3(1) = '0') THEN
                        P_ERR := '1';
                        WIP   := '1';
                    ELSE
                        PWDMLB    := slv_3(2);
                        PSTMLB    := slv_3(1);
                    END IF;

                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_password      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    Password_reg := to_slv(command.data4, 16)&
                                    to_slv(command.data3, 16)&
                                    to_slv(command.data2, 16)&
                                    to_slv(command.data1, 16);
                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    psw_unlock      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSU,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSU,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err THEN
                    Pass_tmp := to_slv(command.data4, 16)&
                                to_slv(command.data3, 16)&
                                to_slv(command.data2, 16)&
                                to_slv(command.data1, 16);
                    IF Pass_tmp = Password_reg  AND PWDMLB = '0' THEN
                        PPB_LOCK := '1';
                        WEL      := '0';
                        WVREG := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbl_reg_rd       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PLBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PLBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_ppbl_reg       =>

                half_period := half_period3_srl;

                WIP := '1';

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBWR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    PPB_LOCK := '0';
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbacc_rd       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PPBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ppbacc_rd4       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PPBRD4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    w_ppb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_ppb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    ppb_ers  =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBERS,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits:= (OTHERS => '1');
                    WEL   := '0';
                    WVREG := '0';
                ELSE
                    E_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    dybacc_rd       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DYBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dybacc_rd4       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DYBRD4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_dyb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

            WHEN    w_dyb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

            WHEN    ecc_read       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_REDUS,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_REDUS,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_REDUS,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_REDUS,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ecc_read4       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_REDUS4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_REDUS4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_REDUS4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_REDUS4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    wt          =>
                WAIT FOR command.wtime;
                WAIT for 50 ns;
                
--             WHEN    CSneg_pulse          =>
--                 CSNeg := '0';
--                 WAIT FOR command.wtime;
--                 CSNeg := '1';


            WHEN    inv_write          =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_inv_write,
                          data_num=> command.byte_num,
                          opcode  => to_slv(command.data1,8));

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF BP0 = '0' AND BP1 = '0' AND BP2 = '0' THEN
                        FOR i IN 0 TO ADDRRange LOOP
                            mem(i) := 16#FF#;
                        END LOOP;
                        E_ERR := '0';
                    ELSE
                        E_ERR := '0';
                    END IF;
                    WEL := '0';
                    WVREG := '0';
                END IF;
                
            WHEN    seerc_rd  =>

                SECTOR := command.sect;
                ADDR := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_SEERC,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_SEERC,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);

                        E_ERR := '0';
                        WEL   := '0';
                        WIP   := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                END IF;
                
            WHEN    assert_cs  =>

                tm      := command.wtime;

                bus_cycle(bus_cmd => bus_select);
--                     WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect);
            
            WHEN    jedec_reset  =>

                tm                  := command.wtime;
                jedec_reset_active  <= '1';
                -- First CS# assertion
                T_SI    <= '0';

                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                -- Wait for CS# deassertion hold time
                WAIT FOR tm;

                -- Second CS# assertion
                T_SI    <= '1';
                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                -- Wait for CS# deassertion hold time
                WAIT FOR tm;

                -- Third CS# assertion
                T_SI    <= '0';
                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);
				
				-- Wait for CS# deassertion hold time
                WAIT FOR tm;

                -- Fourth CS# assertion
                T_SI    <= '1';
                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                jedec_reset_active  <= '0';

            WHEN    OTHERS  =>  null;
        END CASE;

    END PROCEDURE;

    VARIABLE cmd_cnt    :   NATURAL;
    VARIABLE command    :   cmd_rec;

BEGIN
    TestInit(TimingModel, LongTimming);
    Pick_TC (Model   =>  "s25hs01gt");

    Tseries <=  ts_cnt  ;
    Tcase   <=  tc_cnt  ;

    Generate_TC
        (Model       => TimingModel ,
         Series      => ts_cnt,
         TestCase    => tc_cnt,
         Sec_Arch    => BootConfig,
         command_seq => cmd_seq);

    cmd_cnt := 1;
    WHILE cmd_seq(cmd_cnt).cmd /= done LOOP
        command  := cmd_seq(cmd_cnt);
        status   <=  command.status;
        cmd      <=  command.cmd;
        read_num <= command.byte_num;
        cmd_dc(command);
        cmd_cnt :=cmd_cnt +1;
    END LOOP;

END PROCESS tb;

-------------------------------------------------------------------------------
-- Checker process,
-------------------------------------------------------------------------------
checker: PROCESS
    VARIABLE Addr_reg    : std_logic_vector(31 downto 0);
    VARIABLE RDAR_reg    : std_logic_vector(7 downto 0);
    VARIABLE Data_reg    : std_logic_vector(63 downto 0);
    VARIABLE DLP0_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP1_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP2_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP3_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP_ACT     : std_logic_vector(1 downto 0);
    VARIABLE DLP_EN      : std_logic;
    VARIABLE Pass_out    : std_logic_vector(63 downto 0);
    VARIABLE address     : NATURAL RANGE 0 TO AddrRANGE+1;
    VARIABLE byte        : NATURAL;
    VARIABLE IDLength    : NATURAL RANGE 16#00# TO 16#0F#;
    VARIABLE SFDPaddress : NATURAL RANGE 16#0000# TO 16#0247#;
    VARIABLE tmp         : NATURAL;
    VARIABLE Lat_cnt     : NATURAL;
    VARIABLE Reg_Lat_cnt : NATURAL;
    VARIABLE SecAddr     : NATURAL RANGE 0 TO AddrRANGE;
    VARIABLE AutoBoot_reg_rd : std_logic_vector(31 downto 0);

BEGIN

    IF (T_CSNeg='0') THEN
        DLP_EN := '0';
        DLP0_reg(7 downto 0) := (OTHERS => '0');
        DLP1_reg(7 downto 0) := (OTHERS => '0');
        DLP2_reg(7 downto 0) := (OTHERS => '0');
        DLP3_reg(7 downto 0) := (OTHERS => '0');

        --Opcode
        IF (status /= rd_cont_dualIO AND status /= rd_cont_dualIO4 AND
            status /= rd_cont_quadIO AND status /= rd_cont_quadIO4 AND
            status /= rd_cont_qddr   AND status /= rd_cont_qddr4   AND
            status /= none AND status /= read_fast_4_IO) THEN
            IF QPI='1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            ELSE
                FOR I IN 7 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            END IF;
        END IF;

        --Address
        --3 Bytes Address
        IF (QPI='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CFR2V(7) = '0') OR
             cmd = read_SFDP) THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_IO3RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CFR2V(7) = '0') OR cmd = read_SFDP THEN
            FOR I IN 23 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = dual_high_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 11 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(23-2*i) := T_SO;
                Addr_reg(22-2*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 23 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_IO3RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_ddr_rd AND CFR2V(7)= '0' THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(23)   := T_IO3RESETNeg;
            Addr_reg(22)   := T_WPNeg;
            Addr_reg(21)   := T_SO;
            Addr_reg(20)   := T_SI;
            FOR I IN 1 TO 5 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(23-4*i)   := T_IO3RESETNeg;
                Addr_reg(22-4*i)   := T_WPNeg;
                Addr_reg(21-4*i)   := T_SO;
                Addr_reg(20-4*i)   := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --4 Bytes Address
        IF (QPI='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CFR2V(7)='1') OR
             cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4) THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_IO3RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CFR2V(7)='1') OR cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4 THEN
            FOR I IN 31 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = dual_high_rd AND CFR2V(7)='1') OR cmd = dual_high_rd_4 THEN
            FOR I IN 0 TO 15 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(31-2*i) := T_SO;
                Addr_reg(30-2*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_rd AND CFR2V(7) = '1') OR cmd = quad_rd_4 THEN
            FOR I IN 0 TO 31 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_rd AND CFR2V(7)='1') OR cmd = quad_high_rd_4 THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_IO3RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_ddr_rd AND CFR2V(7) = '1') OR
               cmd = quad_high_ddr_rd_4 THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(31)   := T_IO3RESETNeg;
            Addr_reg(30)   := T_WPNeg;
            Addr_reg(29)   := T_SO;
            Addr_reg(28)   := T_SI;
            FOR I IN 1 TO 7 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(31-4*i)   := T_IO3RESETNeg;
                Addr_reg(30-4*i)   := T_WPNeg;
                Addr_reg(29-4*i)   := T_SO;
                Addr_reg(28-4*i)   := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --Mode Byte
        
        IF cmd = fast_rd4 THEN
            IF QPI = '1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSE
                FOR I IN 7 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = dual_high_rd OR cmd = dual_high_rd_4 THEN
            IF QPI = '1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSE
                FOR I IN 3 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = quad_high_rd OR cmd = quad_high_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL T_SCK'EVENT;
            END LOOP;
        END IF;

        -- Dummy Bytes
        IF cmd = read_SR1 OR cmd = read_JID OR
        (( cmd = read_SR2 OR cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
         AND QPI = '0') OR
        (( cmd = read_JQID) AND QPI = '1') THEN
        Reg_Lat_cnt := to_nat(CFR3V(7)) + to_nat(CFR3V(7))*to_nat(CFR3V(6));
        ELSIF (( cmd = read_SR2 OR cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
         AND QPI = '1') OR cmd = rdar_read OR cmd = dybacc_rd4 OR cmd = dybacc_rd THEN
        Reg_Lat_cnt := to_nat(CFR3V(7)) + to_nat(CFR3V(6));
        END IF;
        
        Lat_cnt := to_nat(CFR2V(3 DOWNTO 0));
--         Reg_Lat_cnt := to_nat(CFR3V(7 DOWNTO 6));
        IF cmd = read_SFDP THEN
            FOR I IN 7 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF cmd = read_RUID THEN
            FOR I IN 31 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF (cmd = fast_rd OR cmd = otp_read OR 
              cmd = ecc_read OR cmd = ecc_read4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
--                     IF sdf_max_param THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END LOOP;
            END IF;
        ELSIF (cmd = rdar_read) THEN
          IF Addr_reg(23 downto 16) >= "10000000" THEN
                IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
                END IF; 
          ELSE 
                IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
                END IF;
          END IF;
        ELSIF (cmd = dual_high_rd OR cmd = dual_high_rd_4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
            END IF;

        ELSIF (cmd = read_SR2 OR cmd = read_CR1 OR
             cmd = rd_dlp OR cmd = pass_reg_rd OR
             cmd = ppbl_reg_rd OR
             cmd = dybacc_rd OR cmd = dybacc_rd4) THEN
            IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF ( cmd = ppbacc_rd OR cmd = ppbacc_rd4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;

        ELSIF (cmd = read_SR1) THEN

            IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
   
                    WAIT UNTIL rising_edge(T_SCK);
                    DEBUG := 1;
                    WAIT FOR 1 ns;
                    DEBUG := 0;

                END LOOP;
            END IF;
--         ELSIF cmd = fast_rd4 AND QPI = '0' THEN
--            IF Lat_cnt >= 1 THEN
--                 FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
--                     WAIT UNTIL rising_edge(T_SCK);
--                     IF sdf_max_param THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
--                 END LOOP;
--             END IF;
        ELSIF cmd = fast_rd4 AND QPI = '0' THEN
        IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
        ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                            DebugB := 2;
                            WAIT FOR 10 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2.5 ns;
                            END IF;
                            DebugB := 0;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SO;
                            DLP2_reg(7) := T_SO;
                            DLP3_reg(7) := T_SO;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                          DebugB := 2;
                          WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            DebugB := 0;
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SO;
                            DLP2_reg(I) := T_SO;
                            DLP3_reg(I) := T_SO;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SO;
                            DLP2_reg(7) := T_SO;
                            DLP3_reg(7) := T_SO;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SO;
                            DLP2_reg(I) := T_SO;
                            DLP3_reg(I) := T_SO;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
                        IF (sdf_max_param = TRUE) THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END IF;
                DLP_EN := '1';
          END IF;
        ELSIF cmd = fast_rd4 AND QPI = '1' THEN
          IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param30 THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
          ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    WAIT FOR 3.1 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2 ns;
                            END IF;
                    IF (VDLR_reg /= "00000000") THEN
                      IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period;
                     END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                          WAIT FOR 3.1 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2 ns;
                            END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                         IF (sdf_max_param = TRUE) THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;
        ELSIF ((cmd = quad_high_rd or cmd = quad_high_rd_4) AND QPI = '0') THEN
            IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                           
                           
                           DebugB := 2;
                           IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 3*half_period;
                           ELSE
                                WAIT FOR 9.1 ns;
                           END IF;
--                         IF sdf_max_param THEN
--                             WAIT FOR half_period;
-- --                             WAIT FOR half_period/2;
--                          END IF;
                            DebugB := 0;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                          DebugB := 2;
                          IF sdf_max_param = TRUE THEN
                              WAIT UNTIL  falling_edge(T_SCK);
                          ELSE
                              WAIT UNTIL  rising_edge(T_SCK);
                          END IF;
                          IF sdf_max_param30 = FALSE THEN
                              WAIT FOR 3.1 ns;
                          END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            IF sdf_max_param30 THEN
-- --                             WAIT FOR half_period;
                                 WAIT FOR 0 ns;
                            END IF;
                            DebugB := 0;
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                         IF (sdf_max_param = TRUE) THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;
          
        ELSIF (cmd = quad_rd_4 OR cmd = quad_rd
               OR cmd = quad_high_rd OR
                cmd = quad_high_rd_4 ) THEN
            IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
            ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                           DebugB := 2;
                           IF sdf_max_param = TRUE THEN
                                WAIT FOR 2*half_period;
                           ELSE
                                WAIT FOR 0.7 ns;
                           END IF;
                           IF sdf_max_param30 = TRUE  THEN
                                 WAIT FOR 5.2 ns;
                           ELSIF sdf_max_param15 = TRUE  THEN
                                WAIT FOR 5.2 ns; 
                           ELSE
                                WAIT FOR 8.4 ns;
                           END IF;
                           DebugB := 0;
--                         IF sdf_max_param30 THEN
--                             WAIT FOR 2*half_period;
--                             WAIT FOR half_period/2;
--                          END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                          WAIT UNTIL  rising_edge(T_SCK);
                          DebugB := 2;
                          IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 5.5 ns;
                          ELSE
                                WAIT FOR 3.1 ns;
                          END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            IF sdf_max_param THEN
-- --                             WAIT FOR half_period;
                                 WAIT FOR 1 ns;
                            END IF;
                            DebugB := 0;
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                    
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                      IF (sdf_max_param30 = TRUE) THEN
--                             WAIT FOR 2*half_period;
-- --                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;          
                    
        
                
        ELSIF cmd = quad_high_ddr_rd THEN
            IF Lat_cnt >= 1 AND Lat_cnt < 4 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 4 THEN
                IF Lat_cnt = 4 THEN
                    WAIT FOR 6.1 ns;
                    IF (VDLR_reg /= "00000000") THEN
                        DLP0_reg(7) := T_SO;
                        DLP1_reg(7) := T_SI;
                        DLP2_reg(7) := T_WPNeg;
                        DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 6.1 ns;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                ELSE
                    FOR I IN (Lat_cnt-5) DOWNTO 0 LOOP
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    FOR I IN 7 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        IF (sdf_max_param = TRUE) THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                END IF;
                DLP_EN := '1';
            END IF;
        ELSIF cmd = quad_high_ddr_rd_4 THEN
            IF Lat_cnt >= 1 AND Lat_cnt < 4 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 4 THEN
                IF Lat_cnt = 4 THEN
                    DEBUG := 1;
                    WAIT FOR 6.1 ns;
                    DEBUG := 0;
                    IF (VDLR_reg /= "00000000") THEN
                        DLP0_reg(7) := T_SO;
                        DLP1_reg(7) := T_SI;
                        DLP2_reg(7) := T_WPNeg;
                        DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        DEBUG := 1;
                        WAIT FOR 6.1 ns;
                        DEBUG := 0;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                ELSE
                    FOR I IN (Lat_cnt-5) DOWNTO 0 LOOP
                        WAIT UNTIL rising_edge(T_SCK);
                         WAIT FOR 0.1 ns;
                    END LOOP;
                    IF (VDLR_reg /= "00000000") AND sdf_min_param = FALSE THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        IF sdf_max_param30 THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                        IF sdf_max_param15 THEN
--                             WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                    END IF;
                    FOR I IN 7 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                            DebugB := 2;
                            IF (sdf_min_param) THEN
                                WAIT FOR 2 ns;
                            ELSIF (sdf_max_param15) THEN
                                WAIT FOR 1.2 ns;
                            ELSIF (sdf_max_param) THEN
                                WAIT FOR 0.8 ns;
                            ELSE
                                WAIT FOR 0.3 ns;
                            END IF;
                            DebugB := 0;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                DEBUG := 100;
                    WAIT UNTIL falling_edge(T_SCK);
                DEBUG1 := 101;
                        IF sdf_max_param THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                END IF;
                DLP_EN := '1';
            END IF;
        END IF;

        --Data Bytes
        IDLength  := 16#00#;
        SFDPaddress := 16#00#;
        byte        := 0;

        IF (status /= none AND status /= err) THEN
            IF (sdf_max_param = TRUE) AND 
               (cmd = quad_high_rd OR cmd = quad_high_rd_4) 
                     AND (VDLR_reg = "00000000") AND  QPI = '0' THEN
                            WAIT FOR 2*half_period;
--                             WAIT FOR half_period/2;
                        END IF;
         
            FOR I IN read_num-1 DOWNTO 0 LOOP
                Data_reg(7 downto 0) := (OTHERS => '0');
                IF (cmd = dual_high_rd OR cmd = dual_high_rd_4) AND
                   QPI = '0' THEN
                    FOR J IN 0 TO 3 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 5.2 ns;
                            ELSE
                                WAIT FOR 4.3 ns;
                            END IF;
                        ELSIF half_period = half_period_30pF THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            WAIT FOR 4.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-2*J) := T_SO;
                        Data_reg(6-2*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_rd OR cmd = quad_rd_4 THEN
                    FOR J IN 0 TO 1 LOOP
                         IF half_period = half_period3_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                         ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                                IF sdf_max_param = TRUE THEN
                                    WAIT FOR 7.51 ns;
                                ELSIF sdf_min_param = TRUE THEN 
                                    WAIT FOR 2 ns;
                                ELSE
                                    WAIT FOR 5.5 ns;
                                END IF;
                          END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = quad_high_rd OR cmd = quad_high_rd_4) AND QPI = '0' THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            IF MAX30 = '1' AND sdf_min_param = FALSE THEN
                                WAIT UNTIL (falling_edge(T_SCK) OR rising_edge(T_SCK));
                                DEBUG := 1;
                                WAIT FOR 5.3 ns;
                                DEBUG := 0;
                            ELSIF sdf_max_param30 = TRUE THEN
                                WAIT UNTIL rising_edge(T_SCK);
                                DEBUG := 2;
                                WAIT FOR 5.3 ns;
                                DEBUG := 0;
                            ELSE
                                WAIT UNTIL (rising_edge(T_SCK));
                                DEBUG := 3;
                                WAIT FOR 2.3 ns;
                                DEBUG := 0;
                            END IF;
                        ELSIF half_period = half_period_30pF THEN
--                             WAIT FOR 2*half_period;
                                WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                                WAIT FOR 4.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            DEBUG := 4;
                            WAIT FOR 8 ns;
                            DEBUG := 0;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF ((cmd = quad_high_rd OR cmd = quad_high_rd_4) AND QPI = '1')  OR
                      cmd = read_JQID THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF sdf_max_param30 = TRUE THEN
                            DEBUG := 1;
                                WAIT FOR 5.3 ns;
                                DEBUG := 0;
                            ELSE
                                DEBUG := 2;
                                WAIT FOR 4.3 ns;
                                DEBUG := 0;
                            END IF;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            DEBUG := 3;
                            IF sdf_max_param AND (VDLR_reg /= "00000000") THEN
                                WAIT FOR 7.5 ns;
                            ELSE
                                WAIT FOR 8.1 ns;
                            END IF;
                            DEBUG := 0;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_ddr_rd THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        DebugB := 1;
                        IF NOT sdf_max_param15 THEN
                               WAIT FOR 0.2 ns;
                        END IF;
                        IF sdf_max_param30 THEN
                             WAIT FOR 0.5 ns;
                        DebugB := 0;
                        END IF;

                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_ddr_rd_4 THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        IF not sdf_max_param THEN
                        DebugB := 1;
                             WAIT FOR 0.5 ns;
                        DebugB := 0;
                        END IF;

                        --IF not (sdf_min_param OR sdf_max_param) THEN
                        --     WAIT FOR 1.5 ns;
                        --END IF; 
                        IF (VDLR_reg = "00000000") THEN
                            IF sdf_max_param THEN
                                WAIT FOR 0.25 ns;
                            END IF;
                        ELSE
                             DebugB := 1;
                             WAIT FOR 1 ns;
                             
                             IF sdf_max_param15 THEN
                                WAIT FOR 0.5 ns;
                            END IF;
                            DebugB := 0;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = pass_reg_rd AND QPI = '0' THEN
                    FOR J IN 63 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '0' AND Addr_reg(23 downto 20) = "0000"  THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.8 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF sdf_max_param THEN
                            WAIT FOR 4.3 ns;
                            ELSE
                                WAIT FOR 5.2 ns;
                            END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '1' AND Addr_reg(23 downto 20) = "0000" THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4 ns;
                         IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 0.5 ns;
                         END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '0' AND Addr_reg(23 downto 20) = "1000"  THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.5 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '1' AND Addr_reg(23 downto 20) = "1000" THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.5 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = read_SFDP OR cmd = read_RUID) AND QPI = '1' THEN
                     FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                     END LOOP;
                ELSIF (cmd = read_SR1 AND QPI = '0') THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DEBUG := 1;
                            WAIT FOR 4.3 ns;
                            DEBUG := 0;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            DEBUG := 2;
                            WAIT FOR 4.3 ns;
                            DEBUG := 0;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (cmd = read_SR2  AND QPI = '0') THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
--                             IF CFR3V(7 DOWNTO 6) = "00" THEN
                           
                            WAIT FOR 2.3 ns;

--                             END IF;
                            IF sdf_min_param = FALSE THEN
                                WAIT FOR 1.5 ns;
                            END IF;
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                                END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (cmd = read_SR1 AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                            IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 1 ns;
   
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                                END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = read_SR2 AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            
                            WAIT FOR 7.3 ns;
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                            END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF ( cmd = read_JID OR cmd = read_JQID OR
                      (( cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
                          AND QPI = '0')) THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
--                             IF CFR3V(7 DOWNTO 6) = "00" THEN
                          
                            WAIT FOR 2.3 ns;

--                             END IF;
                        ELSIF half_period = half_period_30pF THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            WAIT FOR 2.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF sdf_min_param THEN
                            WAIT FOR 2 ns;
                            ELSIF sdf_max_param THEN
                            WAIT FOR 7.51 ns;
                            IF sdf_max_param30 = TRUE  THEN
                               WAIT FOR 0.5 ns;
                            END IF;
                            ELSE
                            WAIT FOR 5.5 ns;
                            END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (( cmd = read_CR1) AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (  cmd = rd_dlp AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2.8 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (( cmd = ppbl_reg_rd OR 
                      cmd = dybacc_rd OR cmd = ppbacc_rd OR
                      cmd = dybacc_rd4 OR cmd = ppbacc_rd4) AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2.8 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF QPI = '1' AND cmd = otp_read THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = fast_rd  OR cmd = fast_rd4) AND QPI = '0' THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 2;
                            WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            IF sdf_min_param = TRUE THEN
                               WAIT FOR 2 ns;
                            ELSE
                               WAIT FOR 2.2 ns;
                            END IF;
                            IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                            END IF;
                            DebugB := 0;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF QPI = '0' THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF status /= read_fast_4_IO THEN
                                WAIT FOR 4.3 ns;
                                IF sdf_max_param30 = TRUE  THEN
                                    WAIT FOR 0.692 ns;
                                END IF;
                            ELSE 
                            WAIT FOR 4.3 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                    WAIT FOR 0.692 ns;
                               END IF;
                            END IF;
                        ELSIF half_period = half_period2_srl THEN 
                            WAIT UNTIL (falling_edge(T_SCK));
--                             DebugB := 1;
                            WAIT FOR 8 ns;
--                             DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSE
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN 
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 0.692 ns;
                            END IF; 
                        
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                END IF;

                CASE status IS
                    WHEN read | read_4 | read_fast | read_fast_4 |
                         read_dual_hi | read_dual_hi4| read_quad_hi |
                         read_quad_hi4 | rd_quad | rd_quad_4 | read_ddr_quad_hi |
                         read_ddr_quad_hi4 | rd_cont_dualIO | read_fast_4_IO |
                         rd_cont_dualIO4 | rd_cont_quadIO | rd_cont_quadIO4 |
                         rd_cont_qddr | rd_cont_qddr4 =>
                        DLP_ACT := "00";
                        IF (VDLR_reg /= "00000000") AND DLP_EN = '1' THEN
                            IF (status = read_ddr_quad_hi4
                            OR status = read_ddr_quad_hi OR status = read_fast_4
                            OR status = read_fast_4_IO OR status = read_quad_hi OR 
                            status = read_quad_hi4 OR status = rd_quad OR 
                            status = rd_quad_4 OR status = rd_cont_quadIO OR 
                            status = rd_cont_quadIO4 OR status = rd_cont_qddr 
                            OR status = rd_cont_qddr4) 
                            THEN
                                DLP_ACT := "11";
                            END IF;
                            DLP_EN := '0';
                        END IF;

                        --read memory array data and dlp if enabled
                        Check_read (
                            DQ        => Data_reg(7 downto 0),
                            DQ_reg0   => DLP0_reg(7 downto 0),
                            DQ_reg1   => DLP1_reg(7 downto 0),
                            DQ_reg2   => DLP2_reg(7 downto 0),
                            DQ_reg3   => DLP3_reg(7 downto 0),
                            D_mem     => mem(address),
                            DLP_reg   => to_nat(VDLR_reg),
                            D_dlp_act => DLP_ACT,
                            check_err => check_err);

                        IF CFR4V(4) = '0'  OR status = read OR
                           status = read_4 THEN   --Wrap Disabled
                            -- if the highest address is reached
                            IF address = AddrRange THEN
                                address := 0;
                            ELSE
                                address := address + 1;
                            END IF;
                        ELSE          --Wrap Enabled
                            address := address + 1;

                            IF CFR4V(1 DOWNTO 0)= "01" AND
                               address MOD 16 = 0 THEN
                                address:= address - 16;
                            ELSIF CFR4V(1 DOWNTO 0) = "10" AND
                               address MOD 32 = 0 THEN
                                address:= address - 32;
                            ELSIF CFR4V(1 DOWNTO 0) = "11" AND
                               address MOD 64 = 0 THEN
                                address:= address - 64;
                            ELSIF CFR4V(1 DOWNTO 0) = "00" AND
                               address MOD 8 = 0 THEN
                                address:= address - 8;
                            END IF;
                        END IF;

                    WHEN rd_HiZ =>
                        --read memory array data
                        Check_Z (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN rd_U =>
                        --read memory array data
                        Check_X (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN read_otp =>
                        --read otp array data
                        IF address >= OTPLoAddr AND address <= OTPHiAddr THEN
                            Check_otp_read (
                                DQ         => Data_reg(7 downto 0),
                                otp_mem    => Otp(address),
                                check_err  => check_err);

                            address := address +1;
                        END IF;

                    WHEN rd_JID | rd_JQID =>

                        IF (IDLength <= 16#0F#) THEN
                            -- read ID
                            Check_read_JID (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => to_nat(MDID_reg(8*IDLength + 7 downto 8*IDLength)),
                                byte_no     => byte,
                                check_err   => check_err);

                            IDLength := IDLength + 1;
                         END IF;

                         byte := byte + 1;

                    WHEN rd_SFDP =>

                        --IF (address < SFDPHiAddr-27) THEN
                        IF (address < SFDPHiAddr+1) THEN
                            -- read ID
                            Check_read_SFDP (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => SFDP_array(address) ,
                                check_err   => check_err);
                         END IF;

                         address := address + 1;

                    WHEN rd_SR1 =>
                        --read status register1
                        Check_read_sr1 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(STR1V),
                            check_err=> check_err);

                    WHEN rd_SR2 =>
                        --read status register2
                        Check_read_sr2 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(STR2V),
                            check_err=> check_err);

                    WHEN read_rdar =>
                        --read all registers

                        IF address = 16#00000000# THEN
                            RDAR_reg := STR1N;
                        ELSIF address = 16#00000002# THEN
                            RDAR_reg := CFR1N;
                        ELSIF address = 16#00000003# THEN
                            RDAR_reg := CFR2N;
                        ELSIF address = 16#00000004# THEN
                            RDAR_reg := CFR3N;
                        ELSIF address = 16#00000005# THEN
                            RDAR_reg := CFR4N;
                        ELSIF address = 16#00000010# THEN
                            RDAR_reg := NVDLR_reg;
                        ELSIF address = 16#00000020# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(7 DOWNTO 0);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000021# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(15 DOWNTO 8);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000022# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(23 DOWNTO 16);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000023# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(31 DOWNTO 24);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000024# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(39 DOWNTO 32);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000025# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(47 DOWNTO 40);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000026# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(55 DOWNTO 48);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000027# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(63 DOWNTO 56);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000042# THEN
                            RDAR_reg := AutoBoot_reg(7 DOWNTO 0);
                        ELSIF address = 16#00000043# THEN
                            RDAR_reg := AutoBoot_reg(15 DOWNTO 8);
                        ELSIF address = 16#00000044# THEN
                            RDAR_reg := AutoBoot_reg(23 DOWNTO 16);
                        ELSIF address = 16#00000045# THEN
                            RDAR_reg := AutoBoot_reg(31 DOWNTO 24);
                        ELSIF address = 16#00000030# THEN
                            RDAR_reg := ASP_reg(7 DOWNTO 0);
                        ELSIF address = 16#00000031# THEN
                            RDAR_reg := ASP_reg(15 DOWNTO 8);
                        ELSIF address = 16#00800000# THEN
                            RDAR_reg := STR1V;
                        ELSIF address = 16#00800001# THEN
                            RDAR_reg := STR2V;
                        ELSIF address = 16#00800002# THEN
                            RDAR_reg := CFR1V;
                        ELSIF address = 16#00800003# THEN
                            RDAR_reg := CFR2V;
                        ELSIF address = 16#00800004# THEN
                            RDAR_reg := CFR3V;
                        ELSIF address = 16#00800005# THEN
                            RDAR_reg := CFR4V;
                        ELSIF address = 16#00800010# THEN
                            RDAR_reg := VDLR_reg;
                        ELSIF address = 16#00800091# THEN
                            RDAR_reg := "00000001";
                        ELSIF address = 16#00800095# THEN
                            RDAR_reg := DIC_reg(7 DOWNTO 0);
                        ELSIF address = 16#00800096# THEN
                            RDAR_reg := DIC_reg(15 DOWNTO 8);
                        ELSIF address = 16#00800097# THEN
                            RDAR_reg := DIC_reg(23 DOWNTO 16);
                        ELSIF address = 16#00800098# THEN
                            RDAR_reg := DIC_reg(31 DOWNTO 24);
                        ELSIF address = 16#0080009B# THEN
                            RDAR_reg := PPBL;
                        ELSE
                            RDAR_reg := "XXXXXXXX";
                        END IF;

                        IF RDAR_reg /= "XXXXXXXX" THEN

                            Check_rdar (
                                DQ       => Data_reg(7 downto 0),
                                D_mem    => to_nat(RDAR_reg),
                                check_err=> check_err);
                        ELSE
                            Check_X (
                                DQ        => Data_reg(0),
                                check_err => check_err);
                        END IF;

                    WHEN rd_CR1 =>
                        --read configuration register
                        Check_read_config (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(CFR1V),
                            check_err=> check_err);

                    WHEN read_dlp =>
                        --read dlp register
                        Check_read_dlp (
                            DQ       => Data_reg(7 downto 0),
                            DLP_reg  => to_nat(VDLR_reg),
                            check_err=> check_err);

                    WHEN read_autoboot =>
                        --read autoboot register
                        FOR I IN 0 TO 3 LOOP
                            FOR J IN 0 TO 7 LOOP
                                AutoBoot_reg_rd(I*8+J) :=
                                        AutoBoot_reg((3-I)*8+J);
                            END LOOP;
                        END LOOP;
                        Check_read_autoboot (
                            DQ       => Data_reg(31 downto 0),
                            D_mem    => to_nat(AutoBoot_reg_rd),
                            check_err=> check_err);

                    WHEN read_bank =>
                        --read bank address register
                        Check_read_bank (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(Bank_Addr_reg),
                            check_err=> check_err);

                    WHEN read_pass_reg =>
                        --read password register
                        Pass_out := Password_reg(7  downto 0) &
                                    Password_reg(15 downto 8) &
                                    Password_reg(23 downto 16) &
                                    Password_reg(31 downto 24) &
                                    Password_reg(39 downto 32) &
                                    Password_reg(47 downto 40) &
                                    Password_reg(55 downto 48) &
                                    Password_reg(63 downto 56);

                        Check_read_pass_reg (
                            DQ       => Data_reg(63 downto 0),
                            D_mem    => to_nat(Pass_out),
                            check_err=> check_err);

                    WHEN read_ppbl =>
                        --read ppb lock register
                        Check_read_ppbl (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBL),
                            check_err=> check_err);

                    WHEN read_ppbar | read_ppbar_4 =>
                        --read ppb access register
                        Check_read_ppbar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBAR),
                            check_err=> check_err);

                    WHEN read_ecc | read_ecc_4 =>
                        --read ECC register
                        Check_read_ecc (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(ECC_reg),
                            check_err=> check_err);

                    WHEN read_dybar | read_dybar_4 =>
                        --read dyb access register
                        Check_read_dybar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(DYBAR),
                            check_err=> check_err);

                    WHEN rd_ppblock_0 | rd_ppblock_1 =>
                        Check_PPBLOCK_bit (
                            DQ       => PPBL(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wip_0 | rd_wip_1 =>
                        Check_WIP_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wel_0 | rd_wel_1 =>
                        Check_WEL_bit (
                            DQ       => STR1V(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN erase_succ | erase_nosucc =>
                        Check_eers_bit (
                            DQ       => Data_reg(5),
                            sts      => status,
                            check_err=> check_err);

                    WHEN pgm_succ | pgm_nosucc =>
                        Check_epgm_bit (
                            DQ       => Data_reg(6),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_ps_0 | rd_ps_1 =>
                        Check_PS_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_es_0 | rd_es_1 =>
                        Check_ES_bit (
                            DQ       => Data_reg(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN others =>
                        null;

                END CASE;
            END LOOP;
        END IF;
    END IF;

    WAIT ON T_CSNeg;

END PROCESS checker;

    ---------------------------------------------------------------------------
    ---- SFDP Preload Process
    ---------------------------------------------------------------------------
    SFDPPreload : PROCESS

    BEGIN
        -----------------------------------------------------------------------
        --SFDP Header
        -----------------------------------------------------------------------
        SFDP_array(16#0000#) := 16#53#;
        SFDP_array(16#0001#) := 16#46#;
        SFDP_array(16#0002#) := 16#44#;
        SFDP_array(16#0003#) := 16#50#;
        SFDP_array(16#0004#) := 16#08#;
        SFDP_array(16#0005#) := 16#01#;
        SFDP_array(16#0006#) := 16#03#;
        SFDP_array(16#0007#) := 16#FF#;
        -- 1st Parameter Header
        SFDP_array(16#0008#) := 16#00#;
        SFDP_array(16#0009#) := 16#00#;
        SFDP_array(16#000A#) := 16#01#;
        SFDP_array(16#000B#) := 16#14#;
        SFDP_array(16#000C#) := 16#00#;
        SFDP_array(16#000D#) := 16#01#;
        SFDP_array(16#000E#) := 16#00#;
        SFDP_array(16#000F#) := 16#FF#;
        -- 2nd Parameter Header
        SFDP_array(16#0010#) := 16#84#;
        SFDP_array(16#0011#) := 16#00#;
        SFDP_array(16#0012#) := 16#01#;
        SFDP_array(16#0013#) := 16#02#;
        SFDP_array(16#0014#) := 16#50#;
        SFDP_array(16#0015#) := 16#01#;
        SFDP_array(16#0016#) := 16#00#;
        SFDP_array(16#0017#) := 16#FF#;
        -- 3rd Parameter Header
        SFDP_array(16#0018#) := 16#81#;
        SFDP_array(16#0019#) := 16#00#;
        SFDP_array(16#001A#) := 16#01#;
        SFDP_array(16#001B#) := 16#16#;
        SFDP_array(16#001C#) := 16#C8#;
        SFDP_array(16#001D#) := 16#01#;
        SFDP_array(16#001E#) := 16#00#;
        SFDP_array(16#001F#) := 16#FF#;
        -- 4th Parameter Header
        SFDP_array(16#0020#) := 16#87#;
        SFDP_array(16#0021#) := 16#00#;
        SFDP_array(16#0022#) := 16#01#;
        SFDP_array(16#0023#) := 16#1C#;
        SFDP_array(16#0024#) := 16#58#;
        SFDP_array(16#0025#) := 16#01#;
        SFDP_array(16#0026#) := 16#00#;
        SFDP_array(16#0027#) := 16#FF#;
        -- Unused
        FOR I IN  16#0028# TO 16#00FF# LOOP
           SFDP_array(i) := 16#FF#;
        END LOOP;

        ----------------------------------------------------------------------/
        -- JEDEC Basic Flash Parameters
        ----------------------------------------------------------------------/
        -- DWORD-1
        SFDP_array(16#0100#) := 16#E7#;
        SFDP_array(16#0101#) := 16#20#;
        SFDP_array(16#0102#) := 16#FA#;
        SFDP_array(16#0103#) := 16#FF#;
        -- DWORD-2
        SFDP_array(16#0104#) := 16#FF#;
        SFDP_array(16#0105#) := 16#FF#;
        SFDP_array(16#0106#) := 16#FF#;
        SFDP_array(16#0107#) := 16#3F#;
        -- DWORD-3
        SFDP_array(16#0108#) := 16#48#;
        SFDP_array(16#0109#) := 16#EB#;
        SFDP_array(16#010A#) := 16#08#;
        SFDP_array(16#010B#) := 16#6B#;
        -- DWORD-4
        SFDP_array(16#010C#) := 16#00#;
        SFDP_array(16#010D#) := 16#FF#;
        SFDP_array(16#010E#) := 16#88#;
        SFDP_array(16#010F#) := 16#BB#;
        -- DWORD-5
        SFDP_array(16#0110#) := 16#FE#;
        SFDP_array(16#0111#) := 16#FF#;
        SFDP_array(16#0112#) := 16#FF#;
        SFDP_array(16#0113#) := 16#FF#;
        -- DWORD-6
        SFDP_array(16#0114#) := 16#FF#;
        SFDP_array(16#0115#) := 16#FF#;
        SFDP_array(16#0116#) := 16#00#;
        SFDP_array(16#0117#) := 16#FF#;
        -- DWORD-7
        SFDP_array(16#0118#) := 16#FF#;
        SFDP_array(16#0119#) := 16#FF#;
        SFDP_array(16#011A#) := 16#48#;
        SFDP_array(16#011B#) := 16#EB#;
        -- DWORD-8
        SFDP_array(16#011C#) := 16#0C#;
        SFDP_array(16#011D#) := 16#20#;
        SFDP_array(16#011E#) := 16#00#;
        SFDP_array(16#011F#) := 16#FF#;
        -- DWORD-9
        SFDP_array(16#0120#) := 16#00#;
        SFDP_array(16#0121#) := 16#FF#;
        SFDP_array(16#0122#) := 16#12#;
        SFDP_array(16#0123#) := 16#D8#;
        -- DWORD-10
        SFDP_array(16#0124#) := 16#23#;
        SFDP_array(16#0125#) := 16#FA#;
        SFDP_array(16#0126#) := 16#FF#;
        SFDP_array(16#0127#) := 16#8B#;
        -- DWORD-11
        SFDP_array(16#0128#) := 16#82#;
        SFDP_array(16#0129#) := 16#E7#;
        SFDP_array(16#012A#) := 16#FF#;
        SFDP_array(16#012B#) := 16#E6#;
        -- DWORD-12
        SFDP_array(16#012C#) := 16#EC#;
        SFDP_array(16#012D#) := 16#03#;
        SFDP_array(16#012E#) := 16#1C#;
        SFDP_array(16#012F#) := 16#60#;
        -- DWORD-13
        SFDP_array(16#0130#) := 16#8A#;
        SFDP_array(16#0131#) := 16#85#;
        SFDP_array(16#0132#) := 16#7A#;
        SFDP_array(16#0133#) := 16#75#;
        -- DWORD-14
        SFDP_array(16#0134#) := 16#F7#;
        SFDP_array(16#0135#) := 16#66#;
        SFDP_array(16#0136#) := 16#80#;
        SFDP_array(16#0137#) := 16#5C#;
        -- DWORD-15
        SFDP_array(16#0138#) := 16#8C#;
        SFDP_array(16#0139#) := 16#D6#;
        SFDP_array(16#013A#) := 16#DD#;
        SFDP_array(16#013B#) := 16#FF#;
        -- DWORD-16
        SFDP_array(16#013C#) := 16#F9#;
        SFDP_array(16#013D#) := 16#38#;
        SFDP_array(16#013E#) := 16#F8#;
        SFDP_array(16#013F#) := 16#A1#;
        -- DWORD-17
        SFDP_array(16#0140#) := 16#00#;
        SFDP_array(16#0141#) := 16#00#;
        SFDP_array(16#0142#) := 16#00#;
        SFDP_array(16#0143#) := 16#00#;
        -- DWORD-18
        SFDP_array(16#0144#) := 16#00#;
        SFDP_array(16#0145#) := 16#00#;
        SFDP_array(16#0146#) := 16#BC#;
        SFDP_array(16#0147#) := 16#00#;
        -- DWORD-19
        SFDP_array(16#0148#) := 16#00#;
        SFDP_array(16#0149#) := 16#00#;
        SFDP_array(16#014A#) := 16#00#;
        SFDP_array(16#014B#) := 16#00#;
        -- DWORD-20
        SFDP_array(16#014C#) := 16#F7#;
        SFDP_array(16#014D#) := 16#F5#;
        SFDP_array(16#014E#) := 16#FF#;
        SFDP_array(16#014F#) := 16#FF#;

        -- JEDEC 4-Byte Address Instructions Parameter DWORD-1
        SFDP_array(16#0150#) := 16#7B#;
        SFDP_array(16#0151#) := 16#92#;
        SFDP_array(16#0152#) := 16#0F#;
        SFDP_array(16#0153#) := 16#FE#;
        -- JEDEC 4-Byte Address Instructions Parameter DWORD-2
        SFDP_array(16#0154#) := 16#21#;
        SFDP_array(16#0155#) := 16#FF#;
        SFDP_array(16#0156#) := 16#FF#;
        SFDP_array(16#0157#) := 16#DC#;
        
        ----------------------------------------------------------------------/
        -- Status, Control and Configuration Register Map Offsets for
        -- Multi-Chip SPI Memory Devices
        ----------------------------------------------------------------------/
        -- Status, Control and Configuration Register Map DWORD-1
        SFDP_array(16#0158#) := 16#00#;
        SFDP_array(16#0159#) := 16#00#;
        SFDP_array(16#015A#) := 16#80#;
        SFDP_array(16#015B#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-2
        SFDP_array(16#015C#) := 16#00#;
        SFDP_array(16#015D#) := 16#00#;
        SFDP_array(16#015E#) := 16#00#;
        SFDP_array(16#015F#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-3
        SFDP_array(16#0160#) := 16#C0#;
        SFDP_array(16#0161#) := 16#FF#;
        SFDP_array(16#0162#) := 16#C3#;
        SFDP_array(16#0163#) := 16#EB#;
        -- Status, Control and Configuration Register Map DWORD-4
        SFDP_array(16#0164#) := 16#C8#;
        SFDP_array(16#0165#) := 16#FF#;
        SFDP_array(16#0166#) := 16#E3#;
        SFDP_array(16#0167#) := 16#EB#;
        -- Status, Control and Configuration Register Map DWORD-5
        SFDP_array(16#0168#) := 16#00#;
        SFDP_array(16#0169#) := 16#65#;
        SFDP_array(16#016A#) := 16#00#;
        SFDP_array(16#016B#) := 16#90#;
        -- Status, Control and Configuration Register Map DWORD-6
        SFDP_array(16#016C#) := 16#06#;
        SFDP_array(16#016D#) := 16#05#;
        SFDP_array(16#016E#) := 16#00#;
        SFDP_array(16#016F#) := 16#A1#;
        -- Status, Control and Configuration Register Map DWORD-7
        SFDP_array(16#0170#) := 16#00#;
        SFDP_array(16#0171#) := 16#65#;
        SFDP_array(16#0172#) := 16#00#;
        SFDP_array(16#0173#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-8
        SFDP_array(16#0174#) := 16#00#;
        SFDP_array(16#0175#) := 16#65#;
        SFDP_array(16#0176#) := 16#00#;
        SFDP_array(16#0177#) := 16#95#;
        -- Status, Control and Configuration Register Map DWORD-9
        SFDP_array(16#0178#) := 16#71#;
        SFDP_array(16#0179#) := 16#65#;
        SFDP_array(16#017A#) := 16#03#;
        SFDP_array(16#017B#) := 16#D0#;
        -- Status, Control and Configuration Register Map DWORD-10
        SFDP_array(16#017C#) := 16#71#;
        SFDP_array(16#017D#) := 16#65#;
        SFDP_array(16#017E#) := 16#03#;
        SFDP_array(16#017F#) := 16#D0#;
        -- Status, Control and Configuration Register Map DWORD-11
        SFDP_array(16#0180#) := 16#00#;
        SFDP_array(16#0181#) := 16#00#;
        SFDP_array(16#0182#) := 16#00#;
        SFDP_array(16#0183#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-12
        SFDP_array(16#0184#) := 16#B0#;
        SFDP_array(16#0185#) := 16#2E#;
        SFDP_array(16#0186#) := 16#00#;
        SFDP_array(16#0187#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-13
        SFDP_array(16#0188#) := 16#88#;
        SFDP_array(16#0189#) := 16#A4#;
        SFDP_array(16#018A#) := 16#89#;
        SFDP_array(16#018B#) := 16#AA#;
        -- Status, Control and Configuration Register Map DWORD-14
        SFDP_array(16#018C#) := 16#71#;
        SFDP_array(16#018D#) := 16#65#;
        SFDP_array(16#018E#) := 16#03#;
        SFDP_array(16#018F#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-15
        SFDP_array(16#0190#) := 16#71#;
        SFDP_array(16#0191#) := 16#65#;
        SFDP_array(16#0192#) := 16#03#;
        SFDP_array(16#0193#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-16
        SFDP_array(16#0194#) := 16#00#;
        SFDP_array(16#0195#) := 16#00#;
        SFDP_array(16#0196#) := 16#00#;
        SFDP_array(16#0197#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-17
        SFDP_array(16#0198#) := 16#00#;
        SFDP_array(16#0199#) := 16#00#;
        SFDP_array(16#019A#) := 16#00#;
        SFDP_array(16#019B#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-18
        SFDP_array(16#019C#) := 16#00#;
        SFDP_array(16#019D#) := 16#00#;
        SFDP_array(16#019E#) := 16#00#;
        SFDP_array(16#019F#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-19
        SFDP_array(16#01A0#) := 16#00#;
        SFDP_array(16#01A1#) := 16#00#;
        SFDP_array(16#01A2#) := 16#00#;
        SFDP_array(16#01A3#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-20
        SFDP_array(16#01A4#) := 16#00#;
        SFDP_array(16#01A5#) := 16#00#;
        SFDP_array(16#01A6#) := 16#00#;
        SFDP_array(16#01A7#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-21
        SFDP_array(16#01A8#) := 16#00#;
        SFDP_array(16#01A9#) := 16#00#;
        SFDP_array(16#01AA#) := 16#00#;
        SFDP_array(16#01AB#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-22
        SFDP_array(16#01AC#) := 16#00#;
        SFDP_array(16#01AD#) := 16#00#;
        SFDP_array(16#01AE#) := 16#00#;
        SFDP_array(16#01AF#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-23
        SFDP_array(16#01B0#) := 16#00#;
        SFDP_array(16#01B1#) := 16#00#;
        SFDP_array(16#01B2#) := 16#00#;
        SFDP_array(16#01B3#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-24
        SFDP_array(16#01B4#) := 16#00#;
        SFDP_array(16#01B5#) := 16#00#;
        SFDP_array(16#01B6#) := 16#00#;
        SFDP_array(16#01B7#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-25
        SFDP_array(16#01B8#) := 16#00#;
        SFDP_array(16#01B9#) := 16#00#;
        SFDP_array(16#01BA#) := 16#00#;
        SFDP_array(16#01BB#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-26
        SFDP_array(16#01BC#) := 16#71#;
        SFDP_array(16#01BD#) := 16#65#;
        SFDP_array(16#01BE#) := 16#05#;
        SFDP_array(16#01BF#) := 16#D5#;
        -- Status, Control and Configuration Register Map DWORD-27
        SFDP_array(16#01C0#) := 16#71#;
        SFDP_array(16#01C1#) := 16#65#;
        SFDP_array(16#01C2#) := 16#05#;
        SFDP_array(16#01C3#) := 16#D5#;
        -- Status, Control and Configuration Register Map DWORD-28
        SFDP_array(16#01C4#) := 16#00#;
        SFDP_array(16#01C5#) := 16#00#;
        SFDP_array(16#01C6#) := 16#A0#;
        SFDP_array(16#01C7#) := 16#15#;
        
        
        -- Sector Map DWORD-1
        SFDP_array(16#01C8#) := 16#FC#;
        SFDP_array(16#01C9#) := 16#65#;
        SFDP_array(16#01CA#) := 16#FF#;
        SFDP_array(16#01CB#) := 16#08#;
        -- Sector Map DWORD-2
        SFDP_array(16#01CC#) := 16#04#;
        SFDP_array(16#01CD#) := 16#00#;
        SFDP_array(16#01CE#) := 16#80#;
        SFDP_array(16#01CF#) := 16#00#;
        -- Sector Map DWORD-3
        SFDP_array(16#01D0#) := 16#FC#;
        SFDP_array(16#01D1#) := 16#65#;
        SFDP_array(16#01D2#) := 16#FF#;
        SFDP_array(16#01D3#) := 16#40#;
        -- Sector Map DWORD-4
        SFDP_array(16#01D4#) := 16#02#;
        SFDP_array(16#01D5#) := 16#00#;
        SFDP_array(16#01D6#) := 16#80#;
        SFDP_array(16#01D7#) := 16#00#;
        -- Sector Map DWORD-5
        SFDP_array(16#01D8#) := 16#FD#;
        SFDP_array(16#01D9#) := 16#65#;
        SFDP_array(16#01DA#) := 16#FF#;
        SFDP_array(16#01DB#) := 16#04#;
        -- Sector Map DWORD-6
        SFDP_array(16#01DC#) := 16#02#;
        SFDP_array(16#01DD#) := 16#00#;
        SFDP_array(16#01DE#) := 16#80#;
        SFDP_array(16#01DF#) := 16#00#;
        -- Sector Map DWORD-7
        SFDP_array(16#01E0#) := 16#FE#;
        SFDP_array(16#01E1#) := 16#00#;
        SFDP_array(16#01E2#) := 16#02#;
        SFDP_array(16#01E3#) := 16#FF#;
        -- Sector Map DWORD-8
        SFDP_array(16#01E4#) := 16#F1#;
        SFDP_array(16#01E5#) := 16#FF#;
        SFDP_array(16#01E6#) := 16#01#;
        SFDP_array(16#01E7#) := 16#00#;
        -- Sector Map DWORD-9
        SFDP_array(16#01E8#) := 16#F8#;
        SFDP_array(16#01E9#) := 16#FF#;
        SFDP_array(16#01EA#) := 16#01#;
        SFDP_array(16#01EB#) := 16#00#;
        -- Sector Map DWORD-10
        SFDP_array(16#01EC#) := 16#F8#;
        SFDP_array(16#01ED#) := 16#FF#;
        SFDP_array(16#01EE#) := 16#FB#;
        SFDP_array(16#01EF#) := 16#07#;
        -- Sector Map DWORD-11
        SFDP_array(16#01F0#) := 16#FE#;
        SFDP_array(16#01F1#) := 16#03#;
        SFDP_array(16#01F2#) := 16#02#;
        SFDP_array(16#01F3#) := 16#FF#;
        -- Sector Map DWORD-12
        SFDP_array(16#01F4#) := 16#F8#;
        SFDP_array(16#01F5#) := 16#FF#;
        SFDP_array(16#01F6#) := 16#FB#;
        SFDP_array(16#01F7#) := 16#07#;
        -- Sector Map DWORD-13
        SFDP_array(16#01F8#) := 16#F8#;
        SFDP_array(16#01F9#) := 16#FF#;
        SFDP_array(16#01FA#) := 16#01#;
        SFDP_array(16#01FB#) := 16#00#;
        -- Sector Map DWORD-14
        SFDP_array(16#01FC#) := 16#F1#;
        SFDP_array(16#01FD#) := 16#FF#;
        SFDP_array(16#01FE#) := 16#01#;
        SFDP_array(16#01FF#) := 16#00#;
        -- Sector Map DWORD-15
        SFDP_array(16#0200#) := 16#FE#;
        SFDP_array(16#0201#) := 16#01#;
        SFDP_array(16#0202#) := 16#04#;
        SFDP_array(16#0203#) := 16#FF#;
        -- Sector Map DWORD-16
        SFDP_array(16#0204#) := 16#F1#;
        SFDP_array(16#0205#) := 16#FF#;
        SFDP_array(16#0206#) := 16#00#;
        SFDP_array(16#0207#) := 16#00#;
        -- Sector Map DWORD-17
        SFDP_array(16#0208#) := 16#F8#;
        SFDP_array(16#0209#) := 16#FF#;
        SFDP_array(16#020A#) := 16#02#;
        SFDP_array(16#020B#) := 16#00#;
        -- Sector Map DWORD-18
        SFDP_array(16#020C#) := 16#F8#;
        SFDP_array(16#020D#) := 16#FF#;
        SFDP_array(16#020E#) := 16#F7#;
        SFDP_array(16#020F#) := 16#07#;
        -- Sector Map DWORD-19
        SFDP_array(16#0210#) := 16#F8#;
        SFDP_array(16#0211#) := 16#FF#;
        SFDP_array(16#0212#) := 16#02#;
        SFDP_array(16#0213#) := 16#00#;
        -- Sector Map DWORD-20
        SFDP_array(16#0214#) := 16#F1#;
        SFDP_array(16#0215#) := 16#FF#;
        SFDP_array(16#0216#) := 16#00#;
        SFDP_array(16#0217#) := 16#00#;
        -- Sector Map DWORD-21
        SFDP_array(16#0218#) := 16#FF#;
        SFDP_array(16#0219#) := 16#04#;
        SFDP_array(16#021A#) := 16#00#;
        SFDP_array(16#021B#) := 16#FF#;
        -- Sector Map DWORD-22
        SFDP_array(16#021C#) := 16#F8#;
        SFDP_array(16#021D#) := 16#FF#;
        SFDP_array(16#021E#) := 16#FF#;
        SFDP_array(16#021F#) := 16#07#;

        WAIT;
    END PROCESS SFDPPreload;

    ---------------------------------------------------------------------------
    ---- File Read Section - Preload Control
    ---------------------------------------------------------------------------

    default:    PROCESS

    -- text file input variables
        FILE mem_f            : text  is  mem_file;
        FILE otp_f            : text  is  otp_file;
        VARIABLE ind          : NATURAL RANGE 0 TO AddrRANGE := 0;
        VARIABLE otp_ind      : NATURAL RANGE 16#000# TO 16#3FF# := 16#000#;
        VARIABLE buf          : line;

BEGIN
    --Preload Control
    ---------------------------------------------------------------------------
    -- File Read Section
    ---------------------------------------------------------------------------
         -- memory preload
        IF (mem_file(1 to 4) /= "none" AND UserPreload = 1) THEN
            ind := 0;
            Mem := (OTHERS => MaxData);
            WHILE (not ENDFILE (mem_f)) LOOP
                READLINE (mem_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF ind > AddrRANGE THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "memory address range"
                            SEVERITY warning;
                    ELSE
                        ind := h(buf(2 to 8)); --address
                    END IF;
                ELSE
                    Mem(ind) := h(buf(1 to 2));
                    IF ind < AddrRANGE THEN
                        ind := ind + 1;
                    END IF;
                END IF;
            END LOOP;
        END IF;

         -- memory preload
        IF (otp_file(1 to 4) /= "none" AND UserPreload = 1) THEN
            otp_ind := 16#000#;
            Otp := (OTHERS => MaxData);
            WHILE (not ENDFILE (otp_f)) LOOP
                READLINE (otp_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF otp_ind > 16#3FF# OR otp_ind < 16#000# THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "OTP address range"
                            SEVERITY warning;
                    ELSE
                        otp_ind := h(buf(2 to 4)); --address
                    END IF;
                ELSE
                    Otp(otp_ind) := h(buf(1 to 2));
                    otp_ind := otp_ind + 1;
                END IF;
            END LOOP;
        END IF;

        LOCK_BYTE1 := to_slv(Otp(16#10#),8);
        LOCK_BYTE2 := to_slv(Otp(16#11#),8);
        LOCK_BYTE3 := to_slv(Otp(16#12#),8);
        LOCK_BYTE4 := to_slv(Otp(16#13#),8);

    WAIT;

END PROCESS default;

END vhdl_behavioral_static_memory_allocation;


ARCHITECTURE vhdl_behavioral_dynamic_memory_allocation
                                              of testbench_s25hs01gt_verilog IS
    COMPONENT s25hs01gt IS
        GENERIC (

        -- memory file to be loaded
        mem_file_name     : STRING    := "s25hs01gt.mem";
        otp_file_name     : STRING    := "s25hs01gtOTP.mem";

        UserPreload       : INTEGER   := 1;

        -- For FMF SDF technology file usage
        TimingModel       : STRING    := DefaultTimingModel
    );
    PORT (
        -- Data Inputs/Outputs
        SI                : INOUT std_ulogic := 'U'; -- serial data input/IO0
        SO                : INOUT std_ulogic := 'U'; -- serial data output/IO1
        -- Controls
        SCK               : IN    std_ulogic := 'U'; -- serial clock input
        CSNeg             : IN    std_ulogic := 'U'; -- chip select input
        RESETNeg          : INOUT std_ulogic := 'U'; -- hardware reset pin
        WPNeg             : INOUT std_ulogic := 'U'; -- write protect input/IO2
        IO3_RESETNeg      : INOUT std_ulogic := 'U'  -- hold input/IO3
    );
    END COMPONENT s25hs01gt;

    FOR ALL: s25hs01gt USE ENTITY work.s25hs01gt;
    ---------------------------------------------------------------------------
    --memory configuration
    ---------------------------------------------------------------------------
    CONSTANT MaxData       : NATURAL := 16#FF#;        --255;
    CONSTANT MemSize       : NATURAL := 16#7FFFFFF#;
    CONSTANT SecNumUni     : NATURAL := 511;
    CONSTANT SecNumHyb     : NATURAL := 543;
    CONSTANT SecSize4      : NATURAL := 16#FFF#;
    CONSTANT SecSize256    : NATURAL := 16#3FFFF#;
    CONSTANT PageNum512    : NATURAL := 16#1FFFF#;
    CONSTANT PageNum256    : NATURAL := 16#3FFFF#;
    CONSTANT AddrRANGE     : NATURAL := 16#7FFFFFF#;
    CONSTANT HiAddrBit     : NATURAL := 31;
    CONSTANT OTPSize       : NATURAL := 1023;
    CONSTANT OTPLoAddr     : NATURAL := 16#000#;
    CONSTANT OTPHiAddr     : NATURAL := 16#3FF#;
    CONSTANT SFDPSize      : NATURAL := 16#0247#;
    CONSTANT SFDPLoAddr    : NATURAL := 16#0000#;
    CONSTANT SFDPHiAddr    : NATURAL := 16#0247#;

    ---------------------------------------------------------------------------
    --model configuration
    ---------------------------------------------------------------------------
    CONSTANT mem_file           :   string  := "s25hs01gt.mem";
    CONSTANT otp_file           :   string  := "s25hs01gtOTP.mem";
    CONSTANT half_period1_srl   :   time    := 3.01 ns;   --1/(2*166MHz)
    CONSTANT half_period2_srl   :   time    := 10 ns;     --1/(2*50MHz)
    CONSTANT half_period3_srl   :   time    := 3.76 ns;   --1/(2*133MHz)
    CONSTANT half_period_ddr    :   time    := 4.9 ns;    --1/(2*102MHz)
    CONSTANT half_period2_ddr   :   time    := 6.02 ns;   --1/(2*83MHz)
    CONSTANT half_period3_ddr   :   time    := 7.58 ns;   --1/(2*66MHz)
    CONSTANT half_period_30pF   :   time    := 4.24 ns;   --

    CONSTANT UserPreload        :   integer :=  1;
    CONSTANT LongTimming        :   boolean :=  FALSE;
    CONSTANT TimingModel        :   STRING  :=  "S25HS01GTDSMHI010_30pF";
    CONSTANT BootConfig         :   boolean :=  TRUE;
    CONSTANT TopAndBottom       :   boolean :=  FALSE;
    CONSTANT tcss               :   time    := 10 ns;
    CONSTANT tcssh              :   time    := 0 ns;
    ---------------------------------------------------------------------------
    --One Byte Instruction Code
    ---------------------------------------------------------------------------
    CONSTANT I_WRR          :std_logic_vector(7 downto 0) := "00000001";-- 01h
    CONSTANT I_PP           :std_logic_vector(7 downto 0) := "00000010";-- 02h
    CONSTANT I_READ         :std_logic_vector(7 downto 0) := "00000011";-- 03h
    CONSTANT I_WRDI         :std_logic_vector(7 downto 0) := "00000100";-- 04h
    CONSTANT I_RDSR1        :std_logic_vector(7 downto 0) := "00000101";-- 05h
    CONSTANT I_WREN         :std_logic_vector(7 downto 0) := "00000110";-- 06h
    CONSTANT I_RDSR2        :std_logic_vector(7 downto 0) := "00000111";-- 07h
    CONSTANT I_PP4          :std_logic_vector(7 downto 0) := "00010010";-- 12h
    CONSTANT I_READ4        :std_logic_vector(7 downto 0) := "00010011";-- 13h
    CONSTANT I_ABWR         :std_logic_vector(7 downto 0) := "00010101";-- 15h
    CONSTANT I_REDUS4       :std_logic_vector(7 downto 0) := "00011000";-- 18h
    CONSTANT I_REDUS        :std_logic_vector(7 downto 0) := "00011001";-- 19h
    CONSTANT I_CLECC        :std_logic_vector(7 downto 0) := "00011011";-- 1Bh
    CONSTANT I_P4E          :std_logic_vector(7 downto 0) := "00100000";-- 20h
    CONSTANT I_P4E4         :std_logic_vector(7 downto 0) := "00100001";-- 21h
    CONSTANT I_30h          :std_logic_vector(7 downto 0) := "00110000";-- 30h
    CONSTANT I_RDCR1        :std_logic_vector(7 downto 0) := "00110101";-- 35h
    CONSTANT I_DOR          :std_logic_vector(7 downto 0) := "00111011";-- 3Bh
    CONSTANT I_DOR4         :std_logic_vector(7 downto 0) := "00111100";-- 3Ch
    CONSTANT I_DLPRD        :std_logic_vector(7 downto 0) := "01000001";-- 41h
    CONSTANT I_OTPP         :std_logic_vector(7 downto 0) := "01000010";-- 42h
    CONSTANT I_PNVDLR       :std_logic_vector(7 downto 0) := "01000011";-- 43h
    CONSTANT I_BE_60        :std_logic_vector(7 downto 0) := "01100000";-- 60h
    CONSTANT I_RDAR         :std_logic_vector(7 downto 0) := "01100101";-- 65h
    CONSTANT I_RSTEN        :std_logic_vector(7 downto 0) := "01100110";-- 66h
    CONSTANT I_QOR          :std_logic_vector(7 downto 0) := "01101011";-- 6Bh
    CONSTANT I_QOR4         :std_logic_vector(7 downto 0) := "01101100";-- 6Ch
    CONSTANT I_WRAR         :std_logic_vector(7 downto 0) := "01110001";-- 71h
    CONSTANT I_EPS_75       :std_logic_vector(7 downto 0) := "01110101";-- 75h
    CONSTANT I_CLSR         :std_logic_vector(7 downto 0) := "10000010";-- 82h
    CONSTANT I_EPS_85       :std_logic_vector(7 downto 0) := "10000101";-- 85h
    CONSTANT I_RST          :std_logic_vector(7 downto 0) := "10011001";-- 99h
    CONSTANT I_FAST_READ    :std_logic_vector(7 downto 0) := "00001011";-- 0Bh
    CONSTANT I_FAST_READ4   :std_logic_vector(7 downto 0) := "00001100";-- 0Ch
    CONSTANT I_ASPP         :std_logic_vector(7 downto 0) := "00101111";-- 2Fh
    CONSTANT I_WVDLR        :std_logic_vector(7 downto 0) := "01001010";-- 4Ah
    CONSTANT I_OTPR         :std_logic_vector(7 downto 0) := "01001011";-- 4Bh
    CONSTANT I_RUID         :std_logic_vector(7 downto 0) := "01001100";-- 4Ch
    CONSTANT I_WRENV        :std_logic_vector(7 downto 0) := "01010000";-- 50h
    CONSTANT I_RSFDP        :std_logic_vector(7 downto 0) := "01011010";-- 5Ah
    CONSTANT I_DIC          :std_logic_vector(7 downto 0) := "01011011";-- 5Bh
    CONSTANT I_SEERC        :std_logic_vector(7 downto 0) := "01011101";-- 5Dh
    CONSTANT I_EPR_7A       :std_logic_vector(7 downto 0) := "01111010";-- 7Ah
    CONSTANT I_EPR_8A       :std_logic_vector(7 downto 0) := "10001010";-- 8Ah
    CONSTANT I_RDID         :std_logic_vector(7 downto 0) := "10011111";-- 9Fh
    CONSTANT I_PLBWR        :std_logic_vector(7 downto 0) := "10100110";-- A6h
    CONSTANT I_PLBRD        :std_logic_vector(7 downto 0) := "10100111";-- A7h
    CONSTANT I_RDQID        :std_logic_vector(7 downto 0) := "10101111";-- AFh
    CONSTANT I_EPS_B0       :std_logic_vector(7 downto 0) := "10110000";-- B0h
    CONSTANT I_BAM4         :std_logic_vector(7 downto 0) := "10110111";-- B7h
    CONSTANT I_EX4BA_0_0    :std_logic_vector(7 downto 0) := "10111000";-- B8h
    CONSTANT I_DPD          :std_logic_vector(7 downto 0) := "10111001";-- B9h
    CONSTANT I_DIOR         :std_logic_vector(7 downto 0) := "10111011";-- BBh
    CONSTANT I_DIOR4        :std_logic_vector(7 downto 0) := "10111100";-- BCh
    CONSTANT I_SBL          :std_logic_vector(7 downto 0) := "11000000";-- C0h
    CONSTANT I_BE_C7        :std_logic_vector(7 downto 0) := "11000111";-- C7h
    CONSTANT I_EES          :std_logic_vector(7 downto 0) := "11010000";-- D0h
    CONSTANT I_SE           :std_logic_vector(7 downto 0) := "11011000";-- D8h
    CONSTANT I_SE4          :std_logic_vector(7 downto 0) := "11011100";-- DCh
    CONSTANT I_DYBRD4       :std_logic_vector(7 downto 0) := "11100000";-- E0h
    CONSTANT I_DYBWR4       :std_logic_vector(7 downto 0) := "11100001";-- E1h
    CONSTANT I_PPBRD4       :std_logic_vector(7 downto 0) := "11100010";-- E2h
    CONSTANT I_PPBP4        :std_logic_vector(7 downto 0) := "11100011";-- E3h
    CONSTANT I_PPBERS       :std_logic_vector(7 downto 0) := "11100100";-- E4h
    CONSTANT I_PASSP        :std_logic_vector(7 downto 0) := "11101000";-- E8h
    CONSTANT I_PASSU        :std_logic_vector(7 downto 0) := "11101001";-- E9h
    CONSTANT I_RDQIOR       :std_logic_vector(7 downto 0) := "11101011";-- EBh
    CONSTANT I_RDQIOR4      :std_logic_vector(7 downto 0) := "11101100";-- ECh
    CONSTANT I_DDRQIOR      :std_logic_vector(7 downto 0) := "11101101";-- EDh
    CONSTANT I_DDRQIOR4     :std_logic_vector(7 downto 0) := "11101110";-- EEh
    CONSTANT I_RESET        :std_logic_vector(7 downto 0) := "11110000";-- F0h
    CONSTANT I_DYBRD        :std_logic_vector(7 downto 0) := "11111010";-- FAh
    CONSTANT I_DYBWR        :std_logic_vector(7 downto 0) := "11111011";-- FBh
    CONSTANT I_PPBRD        :std_logic_vector(7 downto 0) := "11111100";-- FCh
    CONSTANT I_PPBP         :std_logic_vector(7 downto 0) := "11111101";-- FDh
    CONSTANT I_MBR          :std_logic_vector(7 downto 0) := "11111111";-- FFh

    ---------------------------------------------------------------------------
    --testbench parameters
    ---------------------------------------------------------------------------
    --Flash Memory Array
    TYPE MemArr IS ARRAY (0 TO AddrRANGE)      OF integer RANGE -1 TO MaxData;
    --OTP Array
    TYPE OtpArr IS ARRAY (OTPLoAddr TO OTPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;
    --CFI Array
    TYPE CFIArr IS ARRAY (16#00# TO 16#8E#) OF integer RANGE -1 TO MaxData;

    --SFDP Array
    TYPE SFDPArr IS ARRAY (SFDPLoAddr TO SFDPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;

    ---------------------------------------------------------------------------
    --  memory declaration
    ---------------------------------------------------------------------------
    --             -- Mem(SecAddr)(Address)....
    SHARED  VARIABLE Mem             : MemArr := (OTHERS => MaxData);
    SHARED  VARIABLE Otp             : OtpArr := (OTHERS => MaxData);
    SHARED  VARIABLE CFI_array       : CFIArr;
    SHARED  VARIABLE SFDP_array      : SFDPArr;
    SHARED  VARIABLE half_period     : TIME     := half_period1_srl;--3.01 ns
    SHARED  VARIABLE CSNEG_time      : TIME     := 0 ns;
    SHARED  VARIABLE SO_time         : TIME     := 0 ns;
    SHARED  VARIABLE sdf_max_param   : boolean := FALSE;
    SHARED  VARIABLE sdf_max_param15 : boolean := FALSE;
    SHARED  VARIABLE sdf_max_param30 : boolean := FALSE;
    SHARED  VARIABLE sdf_min_param   : boolean := FALSE;
    SHARED  VARIABLE sdf_min_param15   : boolean := FALSE;
    SHARED  VARIABLE DisableClock    : BOOLEAN    := FALSE;
    
    SIGNAL           tcss_expired    : std_logic  := '0';
    SIGNAL           tcssh_expired   : std_logic  := '0';

    --command sequence
    SHARED VARIABLE cmd_seq         : cmd_seq_type;

    SIGNAL status          : status_type := none;
    SIGNAL cmd             : cmd_type := idle;
    SIGNAL read_num        : NATURAL := 0;

    -- device protection mode
    TYPE protection_type IS ( DEFAULT_PROTECTION,
                              PERSISTENT_PROTECTION,
                              PASSWORD_PROTECTION,
                              PASSWORD_PROTECTION_QPI,
                              SEERC_READ,
                              TEST_JEDEC_RESET,
                              AUTOBOOT_TEST,
                              PROGRAM_PPB_QPI);

    SIGNAL MODE            : protection_type;

    SIGNAL Clock_polarity  : std_logic;
    SIGNAL CSNeg_flag      : std_logic;
    SIGNAL PageSize        :   NATURAL :=  256 ;
    SIGNAL PageNum         :   NATURAL :=  0 ;

    SIGNAL check_err       :   std_logic := '0'; -- Active high on error
    SIGNAL ErrorInTest     :   std_logic := '0';

    ---------------------------------------------------------------------------
    --Personality module:
    --
    --  instanciates the DUT module and adapts generic test signals to it
    ---------------------------------------------------------------------------
    --DUT port
    SIGNAL T_SCK                : std_logic := 'U';
    SIGNAL T_SI                 : std_logic := 'U';
    SIGNAL T_SO                 : std_logic := 'U';

    SIGNAL T_CSNeg_mx           : std_logic := 'U';
    SIGNAL T_CSNeg              : std_logic := 'U';
    SIGNAL T_CSNeg_jr           : std_logic := 'U';
    SIGNAL jedec_reset_active   : std_logic := '0';
    SIGNAL T_RESETNeg           : std_logic := '1';
    SIGNAL T_WPNeg              : std_logic := '1';
    SIGNAL T_IO3RESETNeg        : std_logic := '1';
    
    SIGNAL debug_signal    : std_logic := '0';
    SIGNAL debug_check    : std_logic := '0';

    SHARED VARIABLE MAX30    : std_logic := '0';
    SHARED VARIABLE DEBUG    : std_logic := '0';
    SHARED VARIABLE DEBUG1   : std_logic := '0';

    --Sector Protection Status
    SHARED VARIABLE Sec_Prot     : std_logic_vector (SecNumHyb downto 0) :=
                                                    (OTHERS => '0');
    -----------------------------------------------------------------------
    -- Registers
    -----------------------------------------------------------------------
    --     ***  Status Register 1  ***

    -- Nonvolatile Status Register 1
    SHARED VARIABLE  STR1N   : std_logic_vector(7 downto 0)   := (others => '0');

    ALIAS SRWD_NV      :std_logic IS STR1N(7);
    ALIAS BP2_NV       :std_logic IS STR1N(4);
    ALIAS BP1_NV       :std_logic IS STR1N(3);
    ALIAS BP0_NV       :std_logic IS STR1N(2);

    -- Volatile Status Register 1
    SHARED VARIABLE  STR1V   : std_logic_vector(7 downto 0)   := (others => '0');

    -- Status Register Write Disable Bit
    ALIAS SRWD      :std_logic IS STR1V(7);
    -- Status Register Programming Error Bit
    ALIAS P_ERR     :std_logic IS STR1V(6);
    -- Status Register Erase Error Bit
    ALIAS E_ERR     :std_logic IS STR1V(5);
    -- Status Register Block Protection Bits
    ALIAS BP2       :std_logic IS STR1V(4);
    ALIAS BP1       :std_logic IS STR1V(3);
    ALIAS BP0       :std_logic IS STR1V(2);
    -- Status Register Write Enable Latch Bit
    ALIAS WEL       :std_logic IS STR1V(1);
    -- Status Register Write In Progress Bit
    ALIAS WIP       :std_logic IS STR1V(0);
    
    SHARED VARIABLE  WVREG : std_logic := '0';

    -- Volatile Status Register 2
    SHARED VARIABLE STR2V   : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- DIC Suspend
    ALIAS DICS      :std_logic IS STR2V(4);
    -- DIC Abort
    ALIAS DICA      :std_logic IS STR2V(3);
    -- Erase status
    ALIAS ESTAT     :std_logic IS STR2V(2);
    -- Erase suspend
    ALIAS ES        :std_logic IS STR2V(1);
    -- Program suspend
    ALIAS PS        :std_logic IS STR2V(0);

    -- Nonvolatile Configuration Register 1
    SHARED VARIABLE CFR1N   : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- Split Parameter Sectors both Top and Bottom
    ALIAS SPARM_NV  :std_logic IS CFR1N(6);
    -- Configuration Register TBPROT bit
    ALIAS TBPROT_NV :std_logic IS CFR1N(5);
    -- Configuration Register LOCK bit
    ALIAS LOCK_O    :std_logic IS CFR1N(4);
    -- Configuration Register BPNV bit
    ALIAS BPNV_O    :std_logic IS CFR1N(3);
    -- Configuration Register TBPARM bit
    ALIAS TBPARM_NV :std_logic IS CFR1N(2);
    -- Configuration Register QUAD bit
    ALIAS QUAD_NV   :std_logic IS CFR1N(1);

    --Volatile Configuration Register 1
    SHARED VARIABLE CFR1V    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- Split Parameter Sectors both Top and Bottom
    ALIAS SPARM     :std_logic IS CFR1V(6);
    -- Configuration Register TBPROT bit
    ALIAS TBPROT    :std_logic IS CFR1V(5);
    -- Configuration Register LOCK bit
    ALIAS LOCK      :std_logic IS CFR1V(4);
    -- Configuration Register BPNV bit
    ALIAS BPNV      :std_logic IS CFR1V(3);
    -- Configuration Register TBPARM bit
    ALIAS TBPARM    :std_logic IS CFR1V(2);
    -- Configuration Register QUAD bit
    ALIAS QUAD      :std_logic IS CFR1V(1);
    -- Configuration Register FREEZE bit
    ALIAS FREEZE    :std_logic IS CFR1V(0);

    -- Nonvolatile Configuration Register 2
    SHARED VARIABLE CFR2N   : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Volatile Configuration Register 2
    SHARED VARIABLE CFR2V    : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Configuration Register 2 QPI bit
    ALIAS  QPI    :std_logic IS CFR2V(6);

    -- Nonvolatile Configuration Register 3
    SHARED VARIABLE CFR3N   : std_logic_vector(7 downto 0)
                                            := "00000000";
    -- Volatile Configuration Register 3
    SHARED VARIABLE CFR3V   : std_logic_vector(7 downto 0)
                                            := "00000000";
    -- Nonvolatile Configuration Register 4
    SHARED VARIABLE CFR4N   : std_logic_vector(7 downto 0)
                                            := "00001000";
    -- Volatile Configuration Register 4
    SHARED VARIABLE CFR4V   : std_logic_vector(7 downto 0)
                                            := "00001000";
    --  VDLR Register
    SHARED VARIABLE VDLR_reg    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- NVDLR Register
    SHARED VARIABLE NVDLR_reg     : std_logic_vector(7 downto 0)
                                            := (others => '0');
    -- ASP Register
    SHARED VARIABLE ASP_reg        : std_logic_vector(15 downto 0)
                                                    := (others => '1');
    --Read Password Mode Enable Bit
    ALIAS RPME      :std_logic IS ASP_reg(5);
    --DYB Lock Boot Bit
    ALIAS DYBLBB      :std_logic IS ASP_reg(4);
    --PPB OTP Bit
    ALIAS PPBOTP    :std_logic IS ASP_reg(3);
    -- Password Protection Mode Lock Bit
    ALIAS PWDMLB    :std_logic IS ASP_reg(2);
    --Persistent Protection Mode Lock Bit
    ALIAS PSTMLB    :std_logic IS ASP_reg(1);
    --Permanent Protection Lock bit
    ALIAS PERMLB    :std_logic IS ASP_reg(0);

    --      ***  Password Register  ***
    SHARED VARIABLE Password_reg   : std_logic_vector(63 downto 0)
                                            := (others => '1');
    --      ***  PPB Lock Register  ***
    SHARED VARIABLE PPBL           : std_logic_vector(7 downto 0)
                                            := "00000001";
    --Persistent Protection Mode Lock Bit
    ALIAS PPB_LOCK                  : std_logic IS PPBL(0);

    --      ***  PPB Access Register  ***
    SHARED VARIABLE PPBAR          : std_logic_vector(7 downto 0)
                                            := (others => '1');
    -- PPB_bits(Sec)
    SHARED VARIABLE PPB_bits       : std_logic_vector(SecNumHyb downto 0)
                                            := (OTHERS => '1');
    --      ***  DYB Access Register  ***
    SHARED VARIABLE DYBAR          : std_logic_vector(7 downto 0)
                                            := (others => '1');
    -- DYB(Sec)
    SHARED VARIABLE DYB_bits       : std_logic_vector(SecNumHyb downto 0)
                                            := (others => '1');
    --      ***  AutoBoot Register  ***
    SHARED VARIABLE AutoBoot_reg   : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --AutoBoot Enable Bit
    ALIAS ABE       :std_logic IS AutoBoot_reg(0);

    --      ***  Bank Address Register  ***
    SHARED VARIABLE Bank_Addr_reg  : std_logic_vector(7 downto 0)
                                            := (others => '0');
    --      ***  Pointer Address Registers  ***
    SHARED VARIABLE PNT_ADR_reg_0  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_1  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_2  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE PNT_ADR_reg_3  : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --      ***  Address Trap Register  ***
    SHARED VARIABLE ADDTRAP_reg    : std_logic_vector(31 downto 0)
                                            := (others => '0');
    SHARED VARIABLE DIC_reg        : std_logic_vector(31 downto 0)
                                            := (others => '0');
    --      ***  Sector Erase Count Register  ***
    SHARED VARIABLE SEC_reg        : std_logic_vector(23 downto 0)
                                            := (others => '0');

    SHARED VARIABLE WRAR_reg_in    : std_logic_vector(7 downto 0)
                                            := (others => '0');
    SHARED VARIABLE RDAR_reg       : std_logic_vector(7 downto 0)
                                            := (others => '0');
    SIGNAL SBL_data_in             : std_logic_vector(7 downto 0)
                                            := (others => '0');

    SHARED VARIABLE ECC_reg        : std_logic_vector(7 downto 0)
                                            := (others => '0');
                                            
     SHARED VARIABLE MDID_reg       : std_logic_vector(127 downto 0)
                                            := x"FFFFFFFFFFFFFFFFFFFF90030F1B2B34";
                                      

    -- The Lock Protection Registers for OTP Memory space
    SHARED VARIABLE LOCK_BYTE1 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE2 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE3 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE4 :std_logic_vector(7 downto 0);
    
    SHARED VARIABLE DebugB           : NATURAL := 0;

    SHARED VARIABLE DIC_start_addr : NATURAL RANGE 0 TO AddrRANGE := 0;
    SHARED VARIABLE DIC_end_addr   : NATURAL RANGE 0 TO AddrRANGE := 0;
    SHARED VARIABLE dic_out        : std_logic_vector(31 downto 0) := (others => '0');

    SHARED VARIABLE SECSUSP    :INTEGER RANGE 0 TO SecNumHyb;

    SIGNAL Tseries     : NATURAL;
    SIGNAL Tcase       : NATURAL;

    SIGNAL count       : INTEGER RANGE -1 to 7 := -1;


    SIGNAL PARAMETER_ERASE    : BOOLEAN;

    SHARED VARIABLE ts_cnt  :   NATURAL RANGE 1 TO 42:=1; -- testseries counter
    SHARED VARIABLE tc_cnt  :   NATURAL RANGE 0 TO 15:=0; -- testcase counter
    SHARED VARIABLE mem_data  : INTEGER := -1;

    SHARED VARIABLE Rd_Sec    : INTEGER;
    SHARED VARIABLE Rd_Addr   : INTEGER;

    ---------------------------------------------------------------------------
    -- Memory data initial value.
    -- Default value may be overridden by conigure_memory procedure
    ---------------------------------------------------------------------------
    SHARED VARIABLE max_data     : NATURAL := 16#FF#;

    ---------------------------------------------------------------------------
    -- Handle dynamic memory allocation
    ---------------------------------------------------------------------------
    -- Partition dynamically allocated space for performance

    SHARED VARIABLE corrupt_Sec : std_logic_vector(SecNumHyb downto 0)
                                                            :=(OTHERS=>'0');

    -------------------------------------------------------------------------

    -- ---------------------------------------------------------------------
    -- Data types required to implement link list structure
    -- ---------------------------------------------------------------------
    TYPE mem_data_t;
    TYPE mem_data_pointer_t IS ACCESS mem_data_t;
    TYPE mem_data_t IS RECORD
        key_address  :  INTEGER;
        val_data     :  INTEGER;
        successor    :  mem_data_pointer_t;
    END RECORD;

    -- ---------------------------------------------------------------------
    -- Array of linked lists.
    -- Support memory region partitioning for faster access.
    -- ---------------------------------------------------------------------
    TYPE mem_data_pointer_array_t IS
        ARRAY(NATURAL RANGE <>) OF mem_data_pointer_t;

    SHARED VARIABLE linked_list       :
                         mem_data_pointer_array_t(0 TO SecNumHyb);

    -- ---------------------------------------------------------------------
    -- Override mechanism provided for default parameter values
    -- ---------------------------------------------------------------------
    PROCEDURE configure_memory(
        max_data_c   :  IN INTEGER) IS
    BEGIN
        max_data := max_data_c;
    END PROCEDURE configure_memory;

    -- Asure proper initialization
    PROCEDURE initialize IS
        VARIABLE I  :  INTEGER;
    BEGIN
        FOR I IN 0 TO SecNumHyb LOOP
            linked_list(I) := NULL;
        END LOOP;
    END PROCEDURE initialize;

    -- ---------------------------------------------------------------------
    -- Create linked listed
    -- ---------------------------------------------------------------------
    PROCEDURE create_list(
        key_address  :  IN INTEGER;
        val_data     :  IN INTEGER;
        root         :  INOUT mem_data_pointer_t) IS
    BEGIN
        root := NEW mem_data_t;
        root.successor := NULL;
        root.key_address := key_address;
        root.val_data := val_data;
    END PROCEDURE create_list;

    -- --------------------------------------------------------------------
    -- Iterate through linked listed comapring key values
    -- Stop when key value greater or equal
    -- --------------------------------------------------------------------
    PROCEDURE position_list(
        key_address  :  IN INTEGER;
        root         :  INOUT mem_data_pointer_t;
        found        :  INOUT mem_data_pointer_t;
        prev         :  INOUT mem_data_pointer_t) IS
    BEGIN
        found := root;
        prev := NULL;
        WHILE ((found /= NULL) AND (found.key_address < key_address)) LOOP
            prev := found;
            found := found.successor;
        END LOOP;
    END PROCEDURE position_list;

    -- -------------------------------------------------------------------
    -- Add new element to a linked list
    -- -------------------------------------------------------------------
    PROCEDURE insert_list(
        key_address  :  IN INTEGER;
        val_data     :  IN INTEGER;
        root         :  INOUT mem_data_pointer_t) IS

        VARIABLE new_element  :  mem_data_pointer_t;
        VARIABLE found        :  mem_data_pointer_t;
        VARIABLE prev         :  mem_data_pointer_t;
    BEGIN
        position_list(key_address, root, found, prev);

        -- Insert at list tail
        IF (found = NULL) THEN
            prev.successor := NEW mem_data_t;
            prev.successor.key_address := key_address;
            prev.successor.val_data := val_data;
            prev.successor.successor := NULL;
        ELSE
            -- Element exists, update memory data value
            IF (found.key_address = key_address) THEN
                found.val_data := val_data;
            ELSE
                -- No element found, allocate and link
                new_element := NEW mem_data_t;
                new_element.key_address := key_address;
                new_element.val_data := val_data;
                new_element.successor := found;
                -- Possible root position
                IF (prev /= NULL) THEN
                    prev.successor := new_element;
                ELSE
                    root := new_element;
                END IF;
            END IF;
        END IF;
    END PROCEDURE insert_list;

    -- --------------------------------------------------------------------
    -- Remove element from a linked list
    -- --------------------------------------------------------------------
    PROCEDURE remove_list(
        key_address  :  IN INTEGER;
        root         :  INOUT mem_data_pointer_t) IS

        VARIABLE found      :  mem_data_pointer_t;
        VARIABLE prev       :  mem_data_pointer_t;
    BEGIN
        position_list(key_address, root, found, prev);
        IF (found /= NULL) THEN
            -- Key value match
            IF (found.key_address = key_address) THEN
                -- Handle root position removal
                IF (prev /= NULL) THEN
                    prev.successor := found.successor;
                ELSE
                    root := found.successor;
                END IF;
                DEALLOCATE(found);
            END IF;
        END IF;
    END PROCEDURE remove_list;

    -- -------------------------------------------------------------------
    -- Remove range of elements from a linked list
    -- Higher performance than one-by-one removal
    -- -------------------------------------------------------------------
    PROCEDURE remove_list_range(
        address_low  :  IN INTEGER;
        address_high :  IN INTEGER;
        root         :  INOUT mem_data_pointer_t) IS

        VARIABLE iter          :  mem_data_pointer_t;
        VARIABLE prev          :  mem_data_pointer_t;
        VARIABLE link_element  :  mem_data_pointer_t;
    BEGIN
        iter := root;
        prev := NULL;
        -- Find first linked list element belonging to
        -- a specified address range [address_low, address_high]
        WHILE ((iter /= NULL) AND NOT (
        (iter.key_address >= address_low) AND
        (iter.key_address <= address_high))) LOOP
            prev := iter;
            iter := iter.successor;
        END LOOP;
        -- Continue until address_high reached
        -- Deallocate linked list elements pointed by iterator
        IF (iter /= NULL) THEN
            WHILE ((iter /= NULL) AND
            (iter.key_address >= address_low) AND
            (iter.key_address <= address_high)) LOOP
                link_element := iter.successor;
                DEALLOCATE(iter);
                iter := link_element;
            END LOOP;
            -- Handle possible root value change
            IF prev /= NULL THEN
                prev.successor := link_element;
            ELSE
                root := link_element;
            END IF;
        END IF;
    END PROCEDURE remove_list_range;

    -- ---------------------------------------------------------------------
    -- Address range to be erased
    -- ---------------------------------------------------------------------
    PROCEDURE erase_mem(
        address_low      :  IN INTEGER;
        address_high     :  IN INTEGER;
        linked_list      :  INOUT mem_data_pointer_t) IS

    BEGIN
        remove_list_range(
            address_low,
            address_high,
            linked_list
            );
    END PROCEDURE erase_mem;

    -- --------------------------------------------------------------------
    -- Memory READ operation performed above dynamically allocated space
    -- --------------------------------------------------------------------
    PROCEDURE read_mem(
        linked_list  :  INOUT mem_data_pointer_t;
        data         :  INOUT INTEGER;
        address      :  IN INTEGER) IS

        VARIABLE found     :  mem_data_pointer_t;
        VARIABLE prev      :  mem_data_pointer_t;
        VARIABLE mem_data  :  INTEGER;
    BEGIN
        IF (linked_list = NULL) THEN
            -- Not allocated, not written, initial value
            mem_data := max_data ;
        ELSE
            position_list(address, linked_list, found, prev);
            IF (found /= NULL) THEN
                IF found.key_address = address THEN
                    -- Allocated, val_data stored
                    mem_data := found.val_data;
                ELSE
                    -- Not allocated, not written, initial value
                    mem_data := max_data ;
                END IF;
            ELSE
                -- Not allocated, not written, initial value
                mem_data := max_data ;
            END IF;
        END IF;
        data := mem_data;
    END PROCEDURE read_mem;

    -- ------------------------------------------------------------------
    -- Memory WRITE operation performed above dynamically allocated space
    -- ------------------------------------------------------------------
    PROCEDURE write_mem(
        linked_list  :  INOUT mem_data_pointer_t;
        address      :  IN INTEGER;
        data         :  IN INTEGER) IS

    BEGIN
        IF (data /= max_data ) THEN
            -- Handle possible root value update
            IF (linked_list /= NULL) THEN
                insert_list(address, data, linked_list);
            ELSE
                create_list(address, data, linked_list);
            END IF;
        ELSE
            -- Deallocate if initial value written
            -- No linked list, NOP, initial value implicit
            IF (linked_list /= NULL) THEN
                remove_list(address, linked_list);
            END IF;
        END IF;
    END PROCEDURE write_mem;

    PROCEDURE READ_DATA(
            sectoraddr     : IN NATURAL RANGE 0 TO SecNumHyb;
            addressinsec   : IN NATURAL RANGE 0 TO SecSize256;
            ReadData       : INOUT INTEGER) IS
    BEGIN
        read_mem(linked_list(sectoraddr),
                 ReadData,
                 addressinsec
                );
        IF (ReadData = MaxData AND Corrupt_Sec(sectoraddr) = '1') THEN
            ReadData := -1;
        ELSIF (ReadData = MaxData+1) AND Corrupt_Sec(sectoraddr) = '1' THEN
            ReadData := MaxData;
        END IF;
    END READ_DATA;

    PROCEDURE WRITE_DATA(
        sectoraddr     : IN NATURAL RANGE 0 TO SecNumHyb;
        addressinsec   : IN NATURAL RANGE 0 TO SecSize256;
        WriteData      : IN INTEGER) IS
    BEGIN
        IF (WriteData = MaxData AND Corrupt_Sec(sectoraddr) = '1') THEN
            write_mem(linked_list(sectoraddr),
                      addressinsec,
                      WriteData+1
                      );
        ELSE
            write_mem(linked_list(sectoraddr),
                      addressinsec,
                      WriteData
                      );
        END IF;
    END WRITE_DATA;

    FUNCTION ReturnAddr(ADDR : NATURAL; SADDR : NATURAL;
                        Arch: std_logic; Boot: std_logic; TopBottom: std_logic) RETURN NATURAL IS
        VARIABLE result : NATURAL;
    BEGIN
        IF (TopBottom = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top and Bottom
            IF (SADDR <= 16) THEN
                result := SADDR*(SecSize4+1) + ADDR;
            ELSE
                result := (SADDR-16)*(SecSize256+1) + ADDR;
            END IF;
        ELSIF (Arch = '0' AND Boot = '0') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF (SADDR <= 32) THEN
                result := SADDR*(SecSize4+1) + ADDR;
            ELSE
                result := (SADDR-32)*(SecSize256+1) + ADDR;
            END IF;
        ELSIF (Arch = '0' AND Boot = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF (SADDR <= 511) THEN
                result := SADDR*(SecSize256+1) + ADDR;
            ELSE
            result := AddrRANGE + 1 - 32*(SecSize4+1) +
                      (SADDR-512)*(SecSize4+1)+ ADDR;
            END IF;
        ELSE
        --Uniform Sector Architecture
            result := SADDR*(SecSize256+1) + ADDR;
        END IF;
        RETURN result;
    END ReturnAddr;

    PROCEDURE Sesa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL) IS
    BEGIN
        IF CFR1N(6) = '1' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SectorID <= 16 THEN
                IF SectorID < 16 AND PARAMETER_ERASE THEN
                    AddrLOW  := SectorID*(SecSize4+1);
                    AddrHIGH := SectorID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 16*(SecSize4+1);
                    AddrHIGH := SecSize256;
                END IF;
            ELSE
                AddrLOW  := (SectorID-16)*(SecSize256+1);
                AddrHIGH := (SectorID-16)*(SecSize256+1) + SecSize256;
            END IF;
        ELSIF CFR3V(3) = '0' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SectorID <= 32 THEN
                IF SectorID < 32 AND PARAMETER_ERASE THEN
                    AddrLOW  := SectorID*(SecSize4+1);
                    AddrHIGH := SectorID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 32*(SecSize4+1);
                    AddrHIGH := SecSize256;
                END IF;
            ELSE
                AddrLOW  := (SectorID-32)*(SecSize256+1);
                AddrHIGH := (SectorID-32)*(SecSize256+1) + SecSize256;
            END IF;
        ELSIF CFR3V(3) = '0' AND TBPARM_NV = '1' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF SectorID < 511 THEN
                AddrLOW  := SectorID*(SecSize256+1);
                AddrHIGH := SectorID*(SecSize256+1) + SecSize256;
            ELSE
                IF SectorID > 511 AND PARAMETER_ERASE THEN
                    AddrLOW  := AddrRANGE + 1 - 32*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1);
                    AddrHIGH := AddrRANGE + 1 - 32*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 511*(SecSize256+1);
                    AddrHIGH := AddrRANGE - 32*(SecSize4+1);
                END IF;
            END IF;
        ELSE
            AddrLOW  := SectorID*(SecSize256+1);
            AddrHIGH := SectorID*(SecSize256+1) + SecSize256;
        END IF;
    END Sesa;

    PROCEDURE sepa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL;
        VARIABLE   Addr     : NATURAL) IS
        VARIABLE   Page     : NATURAL;
        VARIABLE   Addr_tmp : NATURAL;
    BEGIN
        Addr_tmp := ReturnAddr(Addr,SectorID, CFR3V(3), TBPARM_NV, SPARM_NV);
        Page     := Addr_tmp/PageSize;-- page number

        AddrLOW  := Page*PageSize;
        AddrHIGH := Page*PageSize + PageSize - 1;

    END sepa;

    BEGIN
        DUT : s25hs01gt
        GENERIC MAP (

        -- memory file to be loaded
        mem_file_name   => "s25hs01gt.mem",
        otp_file_name   => "s25hs01gtOTP.mem",

        UserPreload     => UserPreload,

        -- For FMF SDF technology file usage
        TimingModel     => "S25HS01GTDSMHI010_30pF"
        )
        PORT MAP(
            SCK          => T_SCK,
            SI           => T_SI,
            SO           => T_SO,
            CSNeg        => T_CSNeg_mx,
            RESETNeg     => T_RESETNeg,
            IO3_RESETNeg => T_IO3RESETNeg,
            WPNeg        => T_WPNeg
        );

    Clock_polarity <= '0';--SPI mode: CPO L= 0, CPHA = 0
--     Clock_polarity <= '1';--SPI mode: CPO L= 1, CPHA = 1

    MODE <= DEFAULT_PROTECTION;
--    MODE <= PERSISTENT_PROTECTION;
--    MODE <= PASSWORD_PROTECTION;
--    MODE <= PASSWORD_PROTECTION_QPI;
--    MODE <= SEERC_READ;
--    MODE <= TEST_JEDEC_RESET;
--    MODE <= AUTOBOOT_TEST;
--    MODE <= PROGRAM_PPB_QPI;

    -- Multiplex T_CSNeg in order to generate JEDEC Reset and in order not to
    -- destroy other TB functionality
    T_CSNeg_mx <= T_CSNeg WHEN (jedec_reset_active = '0') ELSE T_CSNeg_jr;

    clk_count: PROCESS(T_SCK)
    BEGIN
        IF rising_edge(T_SCK) THEN
            count <= (count+1) mod 8;
        END IF;
    END PROCESS clk_count;

    clk_generation: PROCESS(T_SCK, T_CSNeg, CSNeg_flag, tcss_expired,
    tcssh_expired)
    BEGIN
        IF CSNeg_flag = '1' THEN
            T_SCK <= Clock_polarity;
        ELSIF NOT(DisableClock) THEN
            T_SCK <= NOT T_SCK AFTER half_period;
        END IF;
    END PROCESS clk_generation;

    max_time: PROCESS (T_CSNeg, T_SO)
    BEGIN
        IF ((ts_cnt = 1) AND (tc_cnt = 1)) THEN
            IF (rising_edge(T_CSNeg) AND (T_SO /= 'Z') AND (T_SO /= 'X')) THEN
                CSNEG_time := NOW;
            ELSIF ((T_CSNeg = '1') AND (T_SO = 'Z')) THEN
                SO_time := NOW - CSNEG_time;
            END IF;
            
            IF SO_time = 8 ns OR SO_time = 20 ns THEN
                sdf_max_param := TRUE;
--                sdf_max_param30 := TRUE;
            END IF;
            IF SO_time = 1.5 ns OR SO_time = 12 ns THEN
                sdf_min_param := TRUE;
            END IF;
            IF (TimingModel(19) = '1' AND (SO_time = 1.5 ns OR SO_time = 12 ns))  THEN
                   sdf_min_param15 := TRUE;
            ELSE
                   sdf_min_param15 := FALSE;
            END IF;
            IF (TimingModel(19) = '3' AND sdf_max_param = TRUE)  THEN
                   sdf_max_param30 := TRUE;
            ELSE
                   sdf_max_param30 := FALSE;
            END IF;
            IF (TimingModel(19) = '1' AND sdf_max_param = TRUE)  THEN
                   sdf_max_param15 := TRUE;
            ELSE
                   sdf_max_param15 := FALSE;
            END IF;
        END IF;
    END PROCESS max_time;

--At the end of the simulation, if ErrorInTest='0' there were no errors
    err_ctrl : PROCESS (check_err)
    BEGIN
        IF check_err = '1' THEN
            ErrorInTest <= '1';
        END IF;
    END PROCESS err_ctrl;

tb  :PROCESS

    --------------------------------------------------------------------------
    -- PROCEDURE to select TC
    -- can be modified to read TC list from file, or to generate random list
    --------------------------------------------------------------------------
    PROCEDURE   Pick_TC
        (Model   :  IN  string  := "s25hs01gt" )
    IS
    BEGIN
    CASE MODE IS
        WHEN DEFAULT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt < 33 THEN
                    TS_cnt := TS_cnt+1;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PERSISTENT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 31;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PASSWORD_PROTECTION   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 34;
                ELSIF TS_cnt = 34 THEN
                    TS_cnt := 35;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
        WHEN PASSWORD_PROTECTION_QPI   => 
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 41;
                ELSIF TS_cnt = 41 THEN
                    TS_cnt := 42;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "Test Ended WITHOUT errors"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    ELSE
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                        REPORT "There were errors in test"
                        SEVERITY note;
                        REPORT "------------------------------------------------------------------"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
            
        WHEN SEERC_READ   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 36;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN TEST_JEDEC_RESET   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 37;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
            
         WHEN AUTOBOOT_TEST   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 38;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
        WHEN PROGRAM_PPB_QPI   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 39;
                ELSIF TS_cnt = 39 THEN
                    TS_cnt := 40;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
        END CASE;
    END PROCEDURE Pick_TC;

    ----------------------------------------------------------------------------
    --bus commands, device specific implementation
    ---------------------------------------------------------------------------

    TYPE bus_type IS (bus_idle,
                      bus_select,     --CS# asseretd
                      bus_select_no_clock,
                      bus_deselect,   --CS# deasserted after write
                      bus_deselect_no_clock,
                      bus_desel_read, --CS# deasserted after read
                      bus_opcode,
                      bus_reset,
					  bus_io3_reset,
                      bus_address,
                      bus_dummy_byte,
                      bus_dummy_clock,
                      bus_mode_byte,
                      bus_data_read,
                      bus_data_write,
                      bus_inv_write); -- write is less then 8 bits

    --bus drive for specific command sequence cycle
    PROCEDURE bus_cycle(
        bus_cmd   :IN   bus_type := bus_idle;
        opcode    :IN   std_logic_vector(7 downto 0) := "00000000";
        data4     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data3     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data2     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data1     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        address   :IN   NATURAL RANGE 0 TO AddrRANGE := 0;
        sector    :IN   INTEGER RANGE 0 TO SecNumHyb := 0;
        data_num  :IN   INTEGER RANGE 0 TO AddrRANGE := 0;
        protect   :IN   boolean                      := false;
        pulse     :IN   boolean                      := false;
        break     :IN   boolean                      := false;
        PowerUp   :IN   boolean                      := false;
        tm        :IN   TIME                         := 0 ns)
    IS
        VARIABLE tmpA         : std_logic_vector(31 downto 0);
        VARIABLE tmpD         : std_logic_vector(7 downto 0);
        VARIABLE tmpD1        : std_logic_vector(15 downto 0);
        VARIABLE tmpAB        : std_logic_vector(31 downto 0);
        VARIABLE tmpPASS      : std_logic_vector(63 downto 0);
        VARIABLE tmpDIC       : std_logic_vector(31 downto 0) := x"00000000";
        VARIABLE tmpData      : std_logic_vector(7 downto 0);
        VARIABLE Latency_code : NATURAL;
        VARIABLE Register_Latency : NATURAL;
        VARIABLE data_tmp4    : NATURAL := 0;
        VARIABLE data_tmp3    : NATURAL := 0;
        VARIABLE data_tmp2    : NATURAL := 0;
        VARIABLE data_tmp1    : NATURAL := 0;
        VARIABLE AddrLo       : NATURAL;
        VARIABLE AddrHi       : NATURAL;
        VARIABLE SECT         : NATURAL;

    BEGIN

        SECT := sector;


        tmpA := to_slv(ReturnAddr(address,SECT, CFR3V(3), TBPARM_NV, SPARM_NV));
        data_tmp4 := data4;
        data_tmp3 := data3;
        data_tmp2 := data2;
        data_tmp1 := data1;
        tmpD := to_slv(data_tmp1, 8);
        tmpD1:= to_slv(data_tmp1, 16);
        tmpAB(15 downto 0) := to_slv(data_tmp1, 16);
        tmpAB(31 downto 16):= to_slv(data_tmp2, 16);
        tmpPASS(63 downto 0):= to_slv(data_tmp4, 16)& to_slv(data_tmp3, 16)&
                               to_slv(data_tmp2, 16)& to_slv(data_tmp1, 16);

--         IF CFR2V(7) = '0' THEN
            tmpDIC := to_slv(address, 32);
--         END IF;

        CASE bus_cmd IS

            WHEN bus_idle        =>
                    MAX30 := '0';
--                     DisableClock  := TRUE;
                    CSNeg_flag <= '1';
                    WAIT FOR 3 ns;
                    T_CSNeg    <= '1';
                    T_CSNeg_jr    <= '1';
                    IF protect THEN
                        WAIT FOR 100 ns;
                        T_WPNeg <= not(T_WPNeg);
                    END IF;
                    WAIT FOR 20 ns;

            WHEN bus_select      =>
                DisableClock  := TRUE;
                tcss_expired  <= '0';
--                 tcssh_expired <= '0';
                T_CSNeg <= '0';
                CSNeg_flag <= '0';
                WAIT FOR tm;
                WAIT FOR tcss;
                DisableClock  := FALSE;
                tcss_expired  <= '1';
                
            WHEN bus_select_no_clock  =>
                DisableClock  := TRUE;
                tcss_expired  <= '0';
                tcssh_expired <= '0';
                T_CSNeg_jr    <= '0';
                WAIT FOR tm;
                WAIT FOR tcss;
                

            WHEN bus_reset  =>
                T_RESETNeg <= '0', '1' AFTER tm;
                WAIT FOR 30 ns;
			
			WHEN bus_io3_reset  =>
				T_IO3RESETNeg <= '0', '1' AFTER tm;
                WAIT FOR 30 ns;

            WHEN bus_inv_write        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                WAIT FOR 1.5 ns;
                FOR I IN 7 downto (data_num+1) LOOP
                    T_SI <= opcode(i);
                    WAIT FOR 2*half_period;
                END LOOP;
                T_SI <= opcode(data_num);

            WHEN bus_opcode        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                IF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
                    WAIT FOR 1.5 ns;
                ELSE
                    WAIT FOR 0.5 ns;
                END IF;
                IF (QPI = '0') THEN

                    FOR I IN 7 downto 1 LOOP
                        T_SI <= opcode(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= opcode(0);
                ELSE
                    T_IO3RESETNeg <= opcode(7);
                    T_WPNeg    <= opcode(6);
                    T_SO       <= opcode(5);
                    T_SI       <= opcode(4);
                    WAIT FOR 2*half_period;
                    T_IO3RESETNeg <= opcode(3);
                    T_WPNeg    <= opcode(2);
                    T_SO       <= opcode(1);
                    T_SI       <= opcode(0);
                END IF;
                -- if number of clock pulses isn't multiple of 8
                IF pulse THEN
                    WAIT FOR 2*half_period;
                END IF;
                IF (cmd = read_CR1 OR cmd = read_SR1 OR cmd = read_SR2
                    OR cmd = rd_dlp OR cmd = read_JID OR cmd = read_JQID
                    OR cmd = ppbl_reg_rd) AND QPI = '1' THEN 
                    WAIT FOR half_period;
                    WAIT FOR 4.75 ns;
                END IF;

            WHEN bus_deselect    =>
                WAIT UNTIL rising_edge(T_SCK);
                IF Clock_polarity = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                ELSE
                    WAIT FOR 3 ns;
                END IF;
--                 DisableClock  := TRUE;
                CSNeg_flag <= '1';
                WAIT FOR 3 ns;
                
                T_CSNeg <= '1';

                IF break THEN
                    WAIT FOR 15 ns;
                ELSE
                    WAIT FOR 30 ns;
                END IF;
                
            WHEN bus_deselect_no_clock  =>
--                 DisableClock  := TRUE;
                WAIT FOR tcssh;
                T_CSNeg_jr       <= '1';

                IF break THEN
                    WAIT FOR 15 ns;
                ELSE
                    WAIT FOR 30 ns;
                END IF;

            WHEN bus_desel_read    =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL rising_edge(T_SCK);
                    IF half_period = half_period1_srl THEN
                        WAIT FOR 3.5 ns;
                    ELSE
                        WAIT FOR 5 ns;
                    END IF;
                ELSE
                    IF half_period = half_period1_srl THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 2 ns;
                    ELSIF half_period = half_period_ddr THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    END IF;
                END IF;
                CSNeg_flag <= '1';
                WAIT FOR 3 ns;
                T_CSNeg <= '1';

                IF QUAD = '1' OR opcode = I_RESET THEN
                    WAIT FOR 2*half_period;
                    T_WPNeg    <= '1';
                    T_RESETNeg <= '1';
                END IF;

            WHEN bus_address     =>
               
                IF QPI = '1' THEN
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                    IF (opcode = I_DDRQIOR AND CFR2V(7) = '0') THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_IO3RESETNeg <= tmpA(23);
                            T_WPNeg    <= tmpA(22);
                            T_SO       <= tmpA(21);
                            T_SI       <= tmpA(20);
                            FOR I IN 4 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 5 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    ELSIF (opcode = I_DDRQIOR4 OR
                          (opcode = I_DDRQIOR AND CFR2V(7) = '1')) THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_IO3RESETNeg <= tmpA(31);
                            T_WPNeg    <= tmpA(30);
                            T_SO       <= tmpA(29);
                            T_SI       <= tmpA(28);
                            FOR I IN 6 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    --QUAD I/O High Performance (3 Bytes Address)
                    ELSIF opcode = I_RDQIOR AND CFR2V(7) = '0' THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 4 LOOP
                            T_IO3RESETNeg <= tmpA(23-4*i);
                            T_WPNeg    <= tmpA(22-4*i);
                            T_SO       <= tmpA(21-4*i);
                            T_SI       <= tmpA(20-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    --QUAD I/O High Performance (4 Bytes Address)
                    ELSIF (opcode = I_RDQIOR AND CFR2V(7) = '1') OR
                        opcode = I_RDQIOR4 THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 6 LOOP
                            T_IO3RESETNeg <= tmpA(31-4*i);
                            T_WPNeg    <= tmpA(30-4*i);
                            T_SO       <= tmpA(29-4*i);
                            T_SI       <= tmpA(28-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    ELSIF (opcode = I_RSFDP OR (CFR2V(7) = '0' AND
                      NOT(opcode = I_REDUS4 OR opcode = I_READ4 OR
                          opcode = I_FAST_READ4 OR opcode = I_DIOR4 OR
                          opcode = I_RDQIOR OR opcode = I_PP4 OR 
                          opcode = I_SE4 OR opcode = I_P4E4 OR
                          opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                          opcode = I_PPBRD4 OR opcode = I_PPBP4 OR
                          opcode = I_QOR4 OR opcode = I_DIC))) THEN
                    --3 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                            FOR I IN 0 TO 4 LOOP
                                T_IO3RESETNeg <= tmpA(23-4*i);
                                T_WPNeg    <= tmpA(22-4*i);
                                T_SO       <= tmpA(21-4*i);
                                T_SI       <= tmpA(20-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpA(3);
                            T_WPNeg    <= tmpA(2);
                            T_SO       <= tmpA(1);
                            T_SI       <= tmpA(0);
                    ELSE
                    --4 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        IF (opcode = I_DIC) THEN
                            FOR I IN 0 TO 6 LOOP
                                T_IO3RESETNeg <= tmpDIC(31-4*i);
                                T_WPNeg    <= tmpDIC(30-4*i);
                                T_SO       <= tmpDIC(29-4*i);
                                T_SI       <= tmpDIC(28-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpDIC(3);
                            T_WPNeg    <= tmpDIC(2);
                            T_SO       <= tmpDIC(1);
                            T_SI       <= tmpDIC(0);
                        ELSE
                            FOR I IN 0 TO 6 LOOP
                                T_IO3RESETNeg <= tmpA(31-4*i);
                                T_WPNeg    <= tmpA(30-4*i);
                                T_SO       <= tmpA(29-4*i);
                                T_SI       <= tmpA(28-4*i);
                                WAIT FOR 2*half_period;
                            END LOOP;
                            T_IO3RESETNeg <= tmpA(3);
                            T_WPNeg    <= tmpA(2);
                            T_SO       <= tmpA(1);
                            T_SI       <= tmpA(0);
                        END IF;
                    END IF;
                --Dual I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_DIOR AND CFR2V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 10 LOOP
                        T_SO <= tmpA(23-2*i);
                        T_SI <= tmpA(22-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --Dual I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_DIOR AND CFR2V(7) = '1') OR
                       opcode = I_DIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 14 LOOP
                        T_SO <= tmpA(31-2*i);
                        T_SI <= tmpA(30-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --QUAD I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_RDQIOR AND CFR2V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 4 LOOP
                        T_IO3RESETNeg <= tmpA(23-4*i);
                        T_WPNeg    <= tmpA(22-4*i);
                        T_SO       <= tmpA(21-4*i);
                        T_SI       <= tmpA(20-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_IO3RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_RDQIOR AND CFR2V(7) = '1') OR
                       opcode = I_RDQIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 6 LOOP
                        T_IO3RESETNeg <= tmpA(31-4*i);
                        T_WPNeg    <= tmpA(30-4*i);
                        T_SO       <= tmpA(29-4*i);
                        T_SI       <= tmpA(28-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_IO3RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                ELSIF (opcode = I_DDRQIOR AND CFR2V(7) = '0') THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_IO3RESETNeg <= tmpA(23);
                        T_WPNeg    <= tmpA(22);
                        T_SO       <= tmpA(21);
                        T_SI       <= tmpA(20);
                        FOR I IN 4 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 5 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                ELSIF (opcode = I_DDRQIOR4 OR
                      (opcode = I_DDRQIOR AND CFR2V(7) = '1')) THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_IO3RESETNeg <= tmpA(31);
                        T_WPNeg    <= tmpA(30);
                        T_SO       <= tmpA(29);
                        T_SI       <= tmpA(28);
                        FOR I IN 6 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 7 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;

                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                --4 Bytes Address
                ELSIF opcode = I_QOR4 OR (opcode = I_QOR AND
                      CFR2V(7) = '1') THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSIF  opcode = I_QOR AND CFR2V(7) = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;

                    FOR I IN 23 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSIF opcode = I_FAST_READ4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
--                     WAIT FOR 3/4*half_period; 
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
 
--                     WAIT FOR 1.5 ns;
--                     IF status =  read_fast_4_IO THEN
--                         WAIT FOR 4 ns;
--                     END IF;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
   

                ELSIF opcode = I_READ4 OR 
                      opcode = I_PP4 OR opcode =I_SE4 OR opcode = I_P4E4 OR
                      opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                      opcode = I_PPBRD4 OR opcode = I_PPBP4 OR opcode = I_REDUS4 OR
                      ((opcode = I_READ OR opcode = I_FAST_READ OR opcode = I_OTPR OR
                      opcode = I_OTPP OR opcode = I_PP OR opcode = I_SE OR
                      opcode = I_P4E OR opcode = I_WRAR OR opcode = I_RDAR OR
                      opcode = I_DYBRD OR opcode = I_DYBWR OR opcode=I_REDUS OR
                      opcode = I_PPBRD OR opcode = I_PPBP OR opcode = I_EES OR 
                      opcode = I_SEERC) AND
                      CFR2V(7) = '1') THEN
--                       IF status =  read_fast_4_IO THEN
--                         WAIT FOR 2.2 ns;
--                     END IF;
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.7 ns;
--                     IF status =  read_fast_4_IO THEN
--                         WAIT FOR 4 ns;
--                     END IF;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSE  --3 Bytes Address
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;

                    FOR I IN 23 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                END IF;
                
           IF (cmd = dybacc_rd OR cmd = dybacc_rd4) AND QPI = '1' THEN 
                    WAIT FOR half_period;
                    WAIT FOR 4.25 ns;
                END IF;

            WHEN bus_mode_byte  =>
                IF QPI = '1' THEN
                    IF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 1.5 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    END IF;
                ELSIF opcode = I_FAST_READ4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;
                    FOR I IN 0 to 6 LOOP
                        T_SI <= tmpD(7-i);
--                         T_SI <= tmpD(6-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
--                     T_SO <= tmpD(1);
                    T_SI <= tmpD(0);
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.1 ns;
                    FOR I IN 0 to 2 LOOP
                        T_SO <= tmpD(7-2*i);
                        T_SI <= tmpD(6-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpD(1);
                    T_SI <= tmpD(0);
                ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.1 ns;
                    T_IO3RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR 2*half_period;
                    T_IO3RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                    WAIT UNTIL T_SCK'EVENT;
                    WAIT FOR 2 ns;
                    T_IO3RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR half_period;
                    T_IO3RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                END IF;

            WHEN bus_dummy_byte  =>
                IF opcode = I_RUID THEN
                    IF QPI = '1' THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 31 downto 1 LOOP
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 31 downto 1 LOOP
                            T_SI <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= 'Z';
                    END IF;
                ELSE
                    IF QPI = '1' THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_SI <= 'Z';
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= 'Z';
                    END IF;
                END IF;

            WHEN bus_dummy_clock  =>
                IF opcode = I_RDSR1 OR opcode = I_RDID OR
                 (( opcode = I_RDSR2 OR opcode = I_RDCR1 OR opcode = I_DLPRD OR opcode = I_PLBRD) 
                  AND QPI = '0') OR
                 (( opcode = I_RDQID) AND QPI = '1') THEN
                 Register_Latency := to_nat(CFR3V(7)) + to_nat(CFR3V(7))*to_nat(CFR3V(6));
                 ELSIF (( opcode = I_RDSR2 OR opcode = I_RDCR1 OR opcode = I_DLPRD OR opcode = I_PLBRD) 
                  AND QPI = '1') OR opcode = I_RDAR OR opcode = I_DYBRD4 OR opcode = I_DYBRD THEN
                 Register_Latency := to_nat(CFR3V(7)) + to_nat(CFR3V(6));
                 END IF;
                Latency_code     := to_nat(CFR2V(3 DOWNTO 0));
--                 Register_Latency := to_nat(CFR3V(7 DOWNTO 6));

                IF QPI = '1' THEN
                    IF opcode = I_RDSR2 OR opcode = I_RDCR1 OR
                    opcode = I_PLBRD OR opcode = I_DLPRD THEN
                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_DYBRD OR opcode = I_DYBRD4 THEN
                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_PPBRD OR opcode = I_PPBRD4 THEN
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_RDSR1 OR opcode = I_RDID OR 
                    opcode = I_RDQID THEN
                        IF Register_Latency = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSIF opcode = I_RDAR THEN
                        IF tmpA(24 downto 17) >= "00100000" THEN -- Volatile Regs
                            IF Register_Latency = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            ELSIF Register_Latency > 1 THEN
                                FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END IF;
                        ELSE -- Non-Volatile Regs
                            IF Latency_code = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            ELSIF Latency_code > 1 THEN
                                FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END IF;
                        END IF;
                    ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                           ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 2 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    ELSE
                        IF Latency_code = 1 THEN
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        ELSIF Latency_code > 1 THEN
                            FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_IO3RESETNeg <= 'Z';
                                T_WPNeg    <= 'Z';
                                T_SI       <= 'Z';
                                T_SO       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END IF;
                    END IF;
                ELSIF (opcode = I_DIOR OR opcode = I_DIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_DDRQIOR OR opcode = I_DDRQIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 2 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 2 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 0.1 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_RDQIOR OR opcode = I_RDQIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns; ----
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns; ----
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_QOR OR opcode = I_QOR4) THEN
                       IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_IO3RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF opcode = I_DYBRD OR opcode = I_DYBRD4 THEN
                    IF Register_Latency = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                    ELSIF Register_Latency > 1 THEN
                        FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                ELSIF  opcode = I_PPBRD OR opcode = I_PPBRD4 THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 0.1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                ELSIF opcode = I_RDSR1 OR opcode = I_RDSR2 OR 
                      opcode = I_RDCR1 OR opcode = I_DLPRD OR
                      opcode = I_RDID OR opcode = I_PLBRD OR 
                      opcode = I_RDQID THEN
                   T_SO       <= 'Z';     
                        
                    IF Register_Latency = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.1 ns;
                        T_SI       <= 'Z';
                    ELSIF Register_Latency > 1 THEN
                            FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_SI       <= 'Z';
                            END LOOP;
                            WAIT FOR 2*half_period;
                            T_SI       <= 'Z';
                        
                        END IF;
                ELSIF opcode = I_RDAR THEN
                        IF tmpA(24 downto 17) >= "00100000" THEN -- Volatile Regs
                            IF Register_Latency = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 0.1 ns;
                                T_SI       <= 'Z';
                            ELSIF Register_Latency > 1 THEN
                                FOR I IN (Register_Latency-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 0.1 ns;
                                T_SI       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_SI       <= 'Z';
                            END IF;
                        ELSE -- Non-Volatile Regs
                            IF Latency_code = 1 THEN
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 1 ns;
                                T_SI       <= 'Z';
                            ELSIF Latency_code > 1 THEN
                                FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                                    WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 1 ns;
                                T_SI       <= 'Z';
                                END LOOP;
                                WAIT FOR 2*half_period;
                                T_SI       <= 'Z';
                            END IF;
                        END IF;
                ELSE
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1 ns;
                        T_SI       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                        
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                END IF;

            WHEN bus_data_read   =>
                IF QPI = '1' OR opcode = I_RDQIOR OR opcode = I_RDQIOR4 OR
                opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 OR
                opcode = I_RDQID THEN
                    WAIT FOR 6.5 ns;
                    
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_IO3RESETNeg <= 'Z';
                    MAX30 := '1';
                ELSIF opcode = I_QOR OR opcode = I_QOR4  THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_IO3RESETNeg <= 'Z';
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                ELSIF opcode = I_FAST_READ4 THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                ELSE
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                END IF;
                IF break THEN
                    FOR I IN data_num-1 downto 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 8 ns;
                    END LOOP;
                ELSE
                    IF opcode = I_FAST_READ4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                    WAIT FOR 8 ns;
  
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                        MAX30 := '1';
                    ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        FOR I IN data_num DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 4 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF ((QPI = '1') AND (opcode = I_RDSR1)) THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                        IF sdf_max_param THEN
                        WAIT FOR  3 ns ;
                        END IF;
                    
                    ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 3 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                           END LOOP;
                       END LOOP;
                   ELSIF opcode = I_QOR OR opcode = I_QOR4 THEN
                       FOR I IN data_num-1 DOWNTO 0 LOOP
                           FOR I IN 1 downto 0 LOOP
                               WAIT UNTIL falling_edge(T_SCK);
                               WAIT FOR 5.8 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF QPI = '1' THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 8 ns;
                            END LOOP;
                        END LOOP;
                    ELSE
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                IF half_period = half_period1_srl THEN
                                    WAIT FOR 3 ns;
                                ELSE
                                    WAIT FOR 7 ns;
                                END IF;
                            END LOOP;
                        END LOOP;
                    END IF;
                END IF;
                --two more bit of data-out sequence
                IF pulse THEN
                    WAIT FOR 4*half_period;
                ELSIF QUAD = '1' THEN
                   WAIT FOR half_period;
                END IF;

            WHEN bus_data_write  =>
                IF cmd = w_autoboot AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 0 to 6 LOOP
--                         T_SI <= tmpAB(i);
                        T_IO3RESETNeg <= tmpAB(31 - I*4);
                        T_WPNeg    <= tmpAB(30 - I*4);
                        T_SO       <= tmpAB(29 - I*4);
                        T_SI       <= tmpAB(28 - I*4);
                        WAIT FOR 2*half_period;
                    END LOOP;
                        T_IO3RESETNeg <= tmpAB(3);
                        T_WPNeg    <= tmpAB(2);
                        T_SO       <= tmpAB(1);
                        T_SI       <= tmpAB(0);
                    tmpAB := AutoBoot_reg;
--                     tmpAB := to_slv(data_tmp2, 16)&to_slv(data_tmp1, 16);
--                      AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
--                   slv_4(7 downto 0) & slv_4(15 downto 8);
                 ELSIF cmd = w_asp AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;

                        T_IO3RESETNeg <= tmpD1(7);
                        T_WPNeg    <=    tmpD1(6);
                        T_SO       <=    tmpD1(5);
                        T_SI       <=    tmpD1(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD1(3);
                        T_WPNeg    <=    tmpD1(2);
                        T_SO       <=    tmpD1(1);
                        T_SI       <=    tmpD1(0);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD1(15);
                        T_WPNeg    <=    tmpD1(14);
                        T_SO       <=    tmpD1(13);
                        T_SI       <=    tmpD1(12);
                        WAIT FOR 2*half_period;
 
                    T_IO3RESETNeg <= tmpD1(11);
                        T_WPNeg    <=    tmpD1(10);
                        T_SO       <=    tmpD1(9);
                        T_SI       <=    tmpD1(8);
                    tmpD1 := to_slv(data_tmp1, 16);
                ELSIF (cmd = w_password OR cmd = psw_unlock) AND QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 1 to 7 LOOP
                            T_IO3RESETNeg <= tmpPASS(I*8-1);
                            T_WPNeg    <=    tmpPASS(I*8-2);
                            T_SO       <=    tmpPASS(I*8-3);
                            T_SI       <=    tmpPASS(I*8-4);
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= tmpPASS(I*8-5);
                            T_WPNeg    <=    tmpPASS(I*8-6);
                            T_SO       <=    tmpPASS(I*8-7);
                            T_SI       <=    tmpPASS(I*8-8);
                            WAIT FOR 2*half_period;
                    END LOOP;
                            T_IO3RESETNeg <= tmpPASS(63);
                            T_WPNeg    <=    tmpPASS(62);
                            T_SO       <=    tmpPASS(61);
                            T_SI       <=    tmpPASS(60);
                            WAIT FOR 2*half_period;
                            T_IO3RESETNeg <= tmpPASS(59);
                            T_WPNeg    <=    tmpPASS(58);
                            T_SO       <=    tmpPASS(57);
                            T_SI       <=    tmpPASS(56);
                ELSIF QPI = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        T_IO3RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_IO3RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                        IF I > 0 THEN
                            WAIT FOR 2*half_period;
                        END IF;
                    END LOOP;
               
                ELSIF cmd = w_scr OR cmd = w_asp THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 15 downto 1 LOOP
                        T_SI <= tmpD1(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpD1(0);
                    tmpD1 := to_slv(data_tmp1, 16);
                ELSIF cmd = w_autoboot AND QPI = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpAB(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpAB(0);
--                     AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
--                                     slv_4(7 downto 0) & slv_4(15 downto 8);
--                     tmpAB := to_slv(data_tmp2, 16)&to_slv(data_tmp1, 16);
                    tmpAB := AutoBoot_reg;
                 
                ELSIF cmd = w_password OR cmd = psw_unlock THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 1 to 7 LOOP
                        FOR J IN 1 to 8 LOOP
                            T_SI <= tmpPASS(I*8-J);
                            WAIT FOR 2*half_period;
                        END LOOP;
                    END LOOP;
                    FOR J IN 1 to 7 LOOP
                        T_SI <= tmpPASS(64-J);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpPASS(56);
               ELSIF cmd = read_JQID OR cmd = quad_rd THEN
                   FOR I IN data_num-1 DOWNTO 0 LOOP
                       WAIT UNTIL falling_edge(T_SCK);
                       WAIT FOR 2 ns;
                       FOR I IN 7 downto 1 LOOP
                           T_SI <= tmpD(i);
                           WAIT FOR 2*half_period;
                       END LOOP;
                       T_SI <= tmpD(0);
                       data_tmp1 := data_tmp1 + 1;
                       tmpD := to_slv(data_tmp1, 8);
                   END LOOP;
                ELSE
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_SI <= tmpD(i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                    END LOOP;
                END IF;

        END CASE;

    END PROCEDURE;

   ----------------------------------------------------------------------------
    --procedure to decode commands into specific bus command sequence
    ---------------------------------------------------------------------------
    PROCEDURE cmd_dc
        (   command  :   IN  cmd_rec   )

    IS

        VARIABLE slv_1, slv_2 : std_logic_vector(7 downto 0);
        VARIABLE slv_3, slv_4 : std_logic_vector(15 downto 0);
        VARIABLE opcode_tmp   : std_logic_vector(7 downto 0);
        VARIABLE Data_byte    : INTEGER RANGE 0 TO 16#FFFF#  := 0;
        VARIABLE Byte_number  : NATURAL RANGE 0 TO 600;
        VARIABLE cnt          : NATURAL RANGE 0 TO 512;
        VARIABLE pgm_page     : NATURAL;
        VARIABLE page_addr    : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrLow      : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE ADDR         : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE ADDR_LOW     : NATURAL;
        VARIABLE ADDR_HIGH    : NATURAL;
        VARIABLE addr_tmp     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrHigh     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE SECTOR       : NATURAL RANGE 0 TO 543;
        VARIABLE BP_bits      : std_logic_vector(2 downto 0) := "000";
        VARIABLE tm           : TIME                         := 0 ns;
        VARIABLE tmp          : NATURAL;
        VARIABLE tmp_byte_num : NATURAL;
        VARIABLE pass_tmp     : std_logic_vector(63 downto 0);
        VARIABLE sec_tmp      : NATURAL RANGE 0 TO 543;
        VARIABLE Sec_addr     : NATURAL RANGE 0 TO SecSize256;
        VARIABLE Bank_Addr_reg_tmp: std_logic_vector(7 downto 0)
                                            := (others => '0');
        VARIABLE dic_tmp      : std_logic;
    BEGIN

        half_period := half_period1_srl;

        CASE command.cmd IS

            WHEN    idle        =>

                bus_cycle(bus_cmd => bus_idle,
                          PowerUp => command.aux=PowerUp,
                          protect => command.aux=violate);

            WHEN    w_enable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WREN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '1';
                END IF;

                WAIT FOR 9*half_period ;
            
            WHEN    w_wrenv    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRENV,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WVREG := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    w_disable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRDI,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '0';
                    WVREG := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    reset_en    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSTEN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                WAIT FOR 9*half_period ;

            WHEN    rst    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RST,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                    STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                    CFR1V(7 DOWNTO 1) := CFR1N(7 DOWNTO 1);

                    CFR2V := CFR2N;
                    CFR3V := CFR3N;
                    CFR4V := CFR4N;

                    VDLR_reg  := NVDLR_reg;

                    IF CFR3V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                        BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-19)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-20)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(19 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-20))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                               ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-23)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-24)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(23 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-24))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-32)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(31 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-32))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-47)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-48)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(47 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-48))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-79)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-80)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(79 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-80))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF SPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-143)) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-144)downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot(143 downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-144))
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSIF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                END IF;
                WAIT for 50 ns;

            WHEN    reset_cmd    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RESET,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                    STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                    CFR1V(7 DOWNTO 1) := CFR1N(7 DOWNTO 1);

                    CFR2V := CFR2N;
                    CFR3V := CFR3N;
                    CFR4V := CFR4N;

                    VDLR_reg  := NVDLR_reg;

                    IF CFR3V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                        BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                END IF;
                WAIT for 50 ns;
                
             WHEN    bax4   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EX4BA_0_0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    CFR2V(7) := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    bam4   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BAM4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    CFR2V(7) := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    ees   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EES,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_EES,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status = chk_sts_1 THEN
                    STR2V(2) := '1';
                ELSIF status = chk_sts_0 THEN
                    STR2V(2) := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    set_bl   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_SBL,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_SBL,
                          data_num => command.byte_num,
                          data1    => command.data1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    Data_byte :=  command.data1;
                    slv_1 := to_slv(Data_byte,8);
                    CFR4V(4)          := slv_1(4);
                    CFR4V(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    h_reset         =>

                bus_cycle(bus_cmd => bus_reset,
                          data_num=> 1,
                          tm      => command.wtime);

                STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                CFR1V := CFR1N;
                CFR2V := CFR2N;
                CFR3V := CFR3N;
                CFR4V := CFR4N;

                IF CFR3V(4) = '1' THEN
                    PageSize <= 512;
                    PageNum <= PageNum512;
                ELSE
                    PageSize <= 256;
                    PageNum <= PageNum256;
                END IF;

                VDLR_reg  := NVDLR_reg;

                IF PWDMLB = '0' THEN
                    PPB_LOCK := '0';
                ELSE
                    PPB_LOCK := '1';
                END IF;

                STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                CASE BP_bits IS

                    WHEN "000" =>
                        Sec_Prot := (OTHERS => '0');

                    WHEN "001" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*63/64)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/64)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "010" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN--BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*31/32)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/32)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "011" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*15/16)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/16)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "100" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*7/8)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/8)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "101" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*3/4)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/4)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "110" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN  --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        Sec_Prot := (OTHERS => '1');
                END CASE;

                WAIT for 50 ns;

            WHEN    h_io3_reset         =>  --Naim add for IO3_RESETNeg hardware reset

                bus_cycle(bus_cmd => bus_io3_reset,
                          data_num=> 1,
                          tm      => command.wtime);

                STR1V(7 DOWNTO 5) := STR1N(7 DOWNTO 5);
                STR1V(1 DOWNTO 0) := STR1N(1 DOWNTO 0);

                CFR1V := CFR1N;
                CFR2V := CFR2N;
                CFR3V := CFR3N;
                CFR4V := CFR4N;

                IF CFR3V(4) = '1' THEN
                    PageSize <= 512;
                    PageNum <= PageNum512;
                ELSE
                    PageSize <= 256;
                    PageNum <= PageNum256;
                END IF;

                VDLR_reg  := NVDLR_reg;

                IF PWDMLB = '0' THEN
                    PPB_LOCK := '0';
                ELSE
                    PPB_LOCK := '1';
                END IF;

                STR1V(4 DOWNTO 2) := STR1N(4 DOWNTO 2);
                BP_bits := STR2V(4) & STR2V(3) & STR2V(2);

                CASE BP_bits IS

                    WHEN "000" =>
                        Sec_Prot := (OTHERS => '0');

                    WHEN "001" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*63/64)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/64)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*63/64+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*63/64+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/64+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/64+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "010" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN--BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*31/32)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/32)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*31/32+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*31/32+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/32+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/32+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "011" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*15/16)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/16)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*15/16+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*15/16+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/16+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/16+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "100" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*7/8)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/8)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*7/8+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*7/8+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/8+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/8+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "101" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)*3/4)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/4)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)*3/4+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)*3/4+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/4+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/4+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN "110" =>
                        IF CFR3V(3) = '1' THEN -- Uniform Architecture
                            IF TBPROT_NV = '0' THEN  --BP starts at Top
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '1');
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '0');
                            ELSE
                                Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                     := (OTHERS => '1');
                                Sec_Prot(SecNumUni downto
                                        (SecNumUni+1)/2)
                                                     := (OTHERS => '0');
                            END IF;
                        ELSE
                            IF TBPARM_NV = '1' THEN
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2-1
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2)
                                                     := (OTHERS => '0');
                                END IF;
                            ELSE
                                IF TBPROT_NV = '0' THEN--BP starts at Top
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8) :=
                                                        (OTHERS => '1');
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '0');
                                ELSE
                                    Sec_Prot((SecNumHyb-31)/2+7
                                           downto 0) := (OTHERS => '1');
                                    Sec_Prot(SecNumHyb downto
                                            (SecNumHyb-31)/2+8)
                                                     := (OTHERS => '0');
                                END IF;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        Sec_Prot := (OTHERS => '1');
                END CASE;

                WAIT for 50 ns;
			
			WHEN    w_sr         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);
                WIP := '1';

                IF status /= err AND WEL = '1' THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN

                        SRWD_NV   := slv_1 (7);
                        SRWD      := slv_1 (7);

                        IF (LOCK_O='0') THEN
                            IF FREEZE ='0' THEN

                                    BP2_NV := slv_1 (4);
                                    BP1_NV := slv_1 (3);
                                    BP0_NV := slv_1 (2);

                                    BP2    := slv_1 (4);
                                    BP1    := slv_1 (3);
                                    BP0    := slv_1 (2);
  

                                BP_bits := BP2 & BP1 & BP0;
                            END IF;
                        END IF;

                        Sec_Prot := (others => '0');
                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    wrar         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRAR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_WRAR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                SECTOR := command.sect;
                ADDR   := command.addr;
                addr_tmp := ReturnAddr(ADDR,SECTOR, CFR3V(3), TBPARM_NV, SPARM_NV);

                Data_byte :=  command.data1;
                slv_1     := to_slv(Data_byte,8);
                WIP       := '1';

                IF status /= err AND (WEL = '1' OR (WVREG = '1'  AND  addr_tmp >= 16#00800000#)) THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN
                        IF addr_tmp = 16#00000000# THEN
                            SRWD_NV   := slv_1 (7);
                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0') THEN
                                IF FREEZE ='0' THEN
 
                                        BP2_NV := slv_1 (4);
                                        BP1_NV := slv_1 (3);
                                        BP0_NV := slv_1 (2);

                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
     

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            Sec_Prot := (others => '0');
                            CASE BP_bits IS

                                WHEN "000" =>
                                    Sec_Prot := (OTHERS => '0');

                                WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN OTHERS =>
                                    Sec_Prot := (OTHERS => '1');
                            END CASE;

                        ELSIF addr_tmp = 16#00000002# THEN
                            IF TBPROT_NV = '0' THEN
                                TBPROT_NV  := slv_1 (5);
                                TBPROT    := slv_1 (5);
                            END IF;

       

                            IF (TBPARM_NV = '0' AND CFR3V(3) = '0') THEN
                                TBPARM_NV  := slv_1 (2);
                                TBPARM    := slv_1 (2);
                            END IF;

--                             IF QPI = '0' THEN
                                QUAD_NV := slv_1(1);
                                QUAD    := slv_1(1);
--                             END IF;
                            
                            IF FREEZE = '0' THEN
                                FREEZE    := slv_1(0);
                            END IF;

                            IF LOCK_O = '0' THEN
                                LOCK_O  := slv_1(4);
                                LOCK    := slv_1(4);
                            END IF;
                        ELSIF addr_tmp = 16#00000003# THEN

                            IF CFR2N(7) = '0' THEN
                                CFR2N(7) := slv_1(7);
                                CFR2V(7)  := slv_1(7);
                            END IF;

                            IF CFR2N(6) = '0'  AND slv_1(6) = '1' THEN
                                CFR2N(6) := slv_1(6);
                                QPI    := slv_1(6);

--                                 QUAD_NV := '1';
--                                 QUAD    := '1';
                            END IF;

                            IF CFR2N(5) = '0' THEN
                                CFR2N(5) := slv_1(5);
                                CFR2V(5)  := slv_1(5);
                            END IF;

                            IF CFR2N(3 DOWNTO 0) = "1000" THEN
                                CFR2N(3 DOWNTO 0) := slv_1(3 DOWNTO 0);
                                CFR2V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000004# THEN
                        
                                CFR3N(7) := slv_1(7);
                                CFR3V(7)  := slv_1(7);

                                CFR3N(6) := slv_1(6);
                                CFR3V(6)  := slv_1(6);

                            IF CFR3N(5) = '0' THEN
                                CFR3N(5) := slv_1(5);
                                CFR3V(5)  := slv_1(5);
                            END IF;

                            IF CFR3N(4) = '0' THEN
                                CFR3N(4) := slv_1(4);
                                CFR3V(4)  := slv_1(4);
                            END IF;

                            IF CFR3N(3) = '0' THEN
                                CFR3N(3) := slv_1(3);
                                CFR3V(3)  := slv_1(3);
                            END IF;

                            IF CFR3N(2) = '0' THEN
                                CFR3N(2) := slv_1(2);
                                CFR3V(2)  := slv_1(2);
                            END IF;

                            IF CFR3N(0) = '0' THEN
                                CFR3N(0) := slv_1(0);
                                CFR3V(0)  := slv_1(0);
                            END IF;

                            IF CFR3V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00000005# THEN

                            IF CFR4N(7 DOWNTO 5) = "000" THEN
                                CFR4N(7 DOWNTO 5) := slv_1(7 DOWNTO 5);
                                CFR4V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            END IF;

                            IF CFR4N(4) = '0' THEN
                                CFR4N(4) := slv_1(4);
                                CFR4V(4)  := slv_1(4);
                            END IF;

                            IF CFR4N(1 DOWNTO 0) = "00" THEN
                                CFR4N(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                                CFR4V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            IF to_nat(NVDLR_reg) > -1 THEN
                                slv_2 := NVDLR_reg;
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                                NVDLR_reg := slv_1;
                                VDLR_reg  := slv_1;
                            END IF;

                        ELSIF addr_tmp = 16#00000020# THEN
                            Password_reg(7 DOWNTO 0) := slv_1;
                        ELSIF addr_tmp = 16#00000021# THEN
                            Password_reg(15 DOWNTO 8) := slv_1;
                        ELSIF addr_tmp = 16#00000022# THEN
                            Password_reg(23 DOWNTO 16) := slv_1;
                        ELSIF addr_tmp = 16#00000023# THEN
                            Password_reg(31 DOWNTO 24) := slv_1;
                        ELSIF addr_tmp = 16#00000024# THEN
                            Password_reg(39 DOWNTO 32) := slv_1;
                        ELSIF addr_tmp = 16#00000025# THEN
                            Password_reg(47 DOWNTO 40) := slv_1;
                        ELSIF addr_tmp = 16#00000026# THEN
                            Password_reg(55 DOWNTO 48) := slv_1;
                        ELSIF addr_tmp = 16#00000027# THEN
                            Password_reg(63 DOWNTO 56) := slv_1;
                        ELSIF addr_tmp = 16#00000030# THEN

                            IF DYBLBB = '1' THEN
                                DYBLBB := slv_1(4);
                            END IF;

                            IF PPBOTP = '1' THEN
                                PPBOTP    := slv_1(3);
                            END IF;

                            IF PERMLB = '1' THEN
                                PERMLB    := slv_1(0);
                            END IF;

                            IF (slv_1(2) = '0' AND slv_1(1) = '0') THEN
                                P_ERR := '1';
                                WIP   := '1';
                            ELSE
                                PWDMLB    := slv_1(2);
                                PSTMLB    := slv_1(1);
                            END IF;

                        ELSIF addr_tmp = 16#00800000# THEN

                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0') THEN
                                IF FREEZE ='0' THEN
  
                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
        

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            Sec_Prot := (others => '0');
                            CASE BP_bits IS

                                WHEN "000" =>
                                    Sec_Prot := (OTHERS => '0');

                                WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                            := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                            := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                            := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                            := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                                WHEN OTHERS =>
                                    Sec_Prot := (OTHERS => '1');
                            END CASE;

                        ELSIF addr_tmp = 16#00800002# THEN

--                             IF QPI = '0' THEN
                                QUAD    := slv_1(1);
--                             END IF;

                            IF FREEZE = '0' THEN
                                FREEZE    := slv_1(0);
                            END IF;

                        ELSIF addr_tmp = 16#00800003# THEN

                            CFR2V(7)  := slv_1(7);
                            QPI    := slv_1(6);
--                             IF slv_1(6) = '1' THEN
--                                 QUAD    := '1';
-- --                             END IF;
                            CFR2V(5)  := slv_1(5);
                            CFR2V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800004# THEN
                        
                             
                            CFR3V(7)  := slv_1(7);
                            CFR3V(6)  := slv_1(6);

                            CFR3V(5)  := slv_1(5);
                            CFR3V(4)  := slv_1(4);
                            CFR3V(3)  := slv_1(3);
                            CFR3V(2)  := slv_1(2);
                            CFR3V(0)  := slv_1(0);

                            IF CFR3V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00800005# THEN

                            CFR4V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            CFR4V(4)           := slv_1(4);
                            CFR4V(3)           := slv_1(3);
                            CFR4V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            VDLR_reg  := slv_1;
                        END IF;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    rdar_read       =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_RDAR,
                          pulse    => false,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_address,
                          opcode   => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_read,
                          opcode   => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          data_num => command.byte_num,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_CR1 =>

                half_period := half_period2_srl;

                IF command.cmd = read_CR1 THEN
                    opcode_tmp      := I_RDCR1;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => opcode_tmp,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => opcode_tmp,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SR1       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR1,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDSR1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR1,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SR2       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR2,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDSR2,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR2,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    clr_sr       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_CLSR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN
                    E_ERR := '0';
                    P_ERR := '0';
                    WIP   := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_scr        =>

                WIP := '1';
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_WRR,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                Data_byte :=  command.data1;
                slv_3 := to_slv(Data_byte,16);

                WAIT FOR 22*half_period ;

                IF status /= err AND WEL = '1'  THEN
                        IF NOT(SRWD = '1' AND T_WPNeg='0') OR (QUAD = '1' OR QPI = '1') THEN

                        SRWD_NV   := slv_3 (15);
                        SRWD      := slv_3 (15);

                        IF (LOCK_O='0' ) THEN
                            IF FREEZE ='0' THEN
 
                                    BP2_NV := slv_3 (12);
                                    BP1_NV := slv_3 (11);
                                    BP0_NV := slv_3 (10);

                                    BP2    := slv_3 (12);
                                    BP1    := slv_3 (11);
                                    BP0    := slv_3 (10);
   

                                BP_bits := BP2 & BP1 & BP0;

--                                 IF TBPROT_NV = '0' THEN
                                    TBPROT_NV  := slv_3 (5);
--                                     TBPROT    := slv_3 (5);
--                                 END IF;


                 

--                                 IF (TBPARM_NV = '0' AND CFR3V(3) = '0') THEN
                                    TBPARM_NV  := slv_3 (2);
--                                     TBPARM    := slv_3 (2);
--                                 END IF;
                            END IF;
                        END IF;

--                         IF QPI = '0' THEN
                            QUAD_NV := slv_3(1);
                            QUAD    := slv_3(1);
--                         END IF;

                        IF FREEZE = '0' THEN
                            FREEZE    := slv_3(0);
                        END IF;

                        IF LOCK_O = '0' THEN
                            LOCK_O  := slv_3(4);
--                             LOCK    := slv_3(4);
                        END IF;

                        Sec_Prot := (others => '0');
                        CASE BP_bits IS

                            WHEN "000" =>
                                Sec_Prot := (OTHERS => '0');

                            WHEN "001" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*63/64)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*63/64-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/64-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/64)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*63/64+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*63/64+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/64+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/64+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "010" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN--BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*31/32)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*31/32-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/32-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/32)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*31/32+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*31/32+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/32+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/32+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "011" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*15/16)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*15/16-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/16-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/16)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*15/16+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*15/16+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/16+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/16+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "100" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*7/8)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*7/8-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/8-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/8)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*7/8+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*7/8+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/8+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/8+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "101" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)*3/4)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)*3/4-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/4-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/4)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)*3/4+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)*3/4+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/4+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/4+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN "110" =>
                                IF CFR3V(3) = '1' THEN -- Uniform Architecture
                                    IF TBPROT_NV = '0' THEN  --BP starts at Top
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '1');
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '0');
                                    ELSE
                                        Sec_Prot((SecNumUni+1)/2-1 downto 0)
                                                             := (OTHERS => '1');
                                        Sec_Prot(SecNumUni downto
                                                (SecNumUni+1)/2)
                                                             := (OTHERS => '0');
                                    END IF;
                                ELSE
                                    IF TBPARM_NV = '1' THEN
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2-1
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2)
                                                             := (OTHERS => '0');
                                        END IF;
                                    ELSE
                                        IF TBPROT_NV = '0' THEN--BP starts at Top
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8) :=
                                                                (OTHERS => '1');
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '0');
                                        ELSE
                                            Sec_Prot((SecNumHyb-31)/2+7
                                                   downto 0) := (OTHERS => '1');
                                            Sec_Prot(SecNumHyb downto
                                                    (SecNumHyb-31)/2+8)
                                                             := (OTHERS => '0');
                                        END IF;
                                    END IF;
                                END IF;

                            WHEN OTHERS =>
                                Sec_Prot := (OTHERS => '1');
                        END CASE;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                    WVREG := '0';
                END IF;

            WHEN    w_dic  =>

                    ADDR_LOW  := to_nat(to_slv(command.data4, 16) & to_slv(command.data3,16));
                    ADDR_HIGH := to_nat(to_slv(command.data2, 16) & to_slv(command.data1,16));

                
                IF command.cmd = w_dic THEN
                    opcode_tmp      := I_DIC;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => ADDR_LOW,
                          tm      => command.wtime);
                          
                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => ADDR_HIGH,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                -- DIC start address 
                dic_out := (others => '0');
                FOR I IN ADDR_LOW TO ADDR_HIGH LOOP
                    slv_3 := to_slv(mem(I),16);
                    FOR J IN 15 DOWNTO 0 LOOP
                        dic_tmp := dic_out(31) XOR slv_3(J);
                        dic_out(31) := dic_out(30);
                        dic_out(30) := dic_out(29);
                        dic_out(29) := dic_out(28);
                        dic_out(28) := dic_out(27) XOR dic_tmp;
                        dic_out(27) := dic_out(26) XOR dic_tmp;
                        dic_out(26) := dic_out(25) XOR dic_tmp;
                        dic_out(25) := dic_out(24) XOR dic_tmp;
                        dic_out(24) := dic_out(23);
                        dic_out(23) := dic_out(22) XOR dic_tmp;
                        dic_out(22) := dic_out(21) XOR dic_tmp;
                        dic_out(21) := dic_out(20);
                        dic_out(20) := dic_out(19) XOR dic_tmp;
                        dic_out(19) := dic_out(18) XOR dic_tmp;
                        dic_out(18) := dic_out(17) XOR dic_tmp;
                        dic_out(17) := dic_out(16);
                        dic_out(16) := dic_out(15);
                        dic_out(15) := dic_out(14);
                        dic_out(14) := dic_out(13) XOR dic_tmp;
                        dic_out(13) := dic_out(12) XOR dic_tmp;
                        dic_out(12) := dic_out(11);
                        dic_out(11) := dic_out(10) XOR dic_tmp;
                        dic_out(10) := dic_out(9) XOR dic_tmp;
                        dic_out(9) := dic_out(8) XOR dic_tmp;
                        dic_out(8) := dic_out(7) XOR dic_tmp;
                        dic_out(7) := dic_out(6);
                        dic_out(6) := dic_out(5) XOR dic_tmp;
                        dic_out(5) := dic_out(4);
                        dic_out(4) := dic_out(3);
                        dic_out(3) := dic_out(2);
                        dic_out(2) := dic_out(1);
                        dic_out(1) := dic_out(0);
                        dic_out(0) :=  dic_tmp;
                    END LOOP;
                END LOOP;
                DIC_reg := dic_out;
                WAIT FOR 10*half_period ;
            WHEN    rd_dlp       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DLPRD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DLPRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DLPRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    rd_4           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ4,
                          data1   => command.data1,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    fast_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    fast_rd4       =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);
                
                IF command.status /= read_fast_4_IO THEN

                          bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ4,
                          pulse   => false,
                          tm      => command.wtime);
                END IF;

                

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);
                          
                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_FAST_READ4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;
--                  IF command.aux = break THEN
--                     WAIT FOR 4*half_period;
--                 END IF;
                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_FAST_READ4);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd_4      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR4,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    quad_rd      =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_QOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_QOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_QOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_QOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_QOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_rd_4      =>

                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_QOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_QOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_QOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_QOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_QOR4);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd_4      =>
            
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 102 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd_4      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 102 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    read_JID       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    read_JQID       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDQID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;
                
             WHEN    read_RUID      =>
             
                half_period := half_period3_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RUID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_RUID,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RUID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    read_SFDP      =>
                
                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSFDP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RSFDP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_RSFDP,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RSFDP,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);
                
--                  data_num=> (SFDPHiAddr+1 - command.addr)/2,

                WAIT FOR 22*half_period ;

            WHEN    sector_erase  | p4_erase =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                IF command.cmd = sector_erase THEN
                    opcode_tmp      := I_SE;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase THEN
                    opcode_tmp      := I_P4E;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);

                        IF NOT(PARAMETER_ERASE) THEN
                            IF CFR3V(3) = '0' AND TBPARM = '0' THEN
                                IF SECTOR <= 32 THEN
                                    Corrupt_Sec(0) := '0';
                                    erase_mem(32*(SecSize4+1),
                                              SecSize256,
                                              linked_list(0));
                                ELSE
                                    Corrupt_Sec(SECTOR-32) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR-32));
                                END IF;
                            ELSIF CFR3V(3) = '0' AND TBPARM_NV = '1' THEN
                                IF SECTOR >= 511 THEN
                                    Corrupt_Sec(511) := '0';
                                    erase_mem(0,
                                            55*(SecSize4+1)-1,
                                            linked_list(511));
                                ELSE
                                    Corrupt_Sec(SECTOR) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR));
                                END IF;
                            ELSE
                                Corrupt_Sec(SECTOR) := '0';
                                erase_mem(0,
                                        SecSize256,
                                        linked_list(SECTOR));
                            END IF;
                        ELSE
                            IF TBPARM = '1' THEN
                                Corrupt_Sec(511) := '0';
                                erase_mem((SECTOR-200)*(SecSize4+1),
                                        (SECTOR-199)*(SecSize4+1)-1,
                                        linked_list(511));
                            ELSE
                                Corrupt_Sec(0) := '0';
                                erase_mem(SECTOR*(SecSize4+1),
                                        (SECTOR+1)*(SecSize4+1)-1,
                                        linked_list(0));
                            END IF;
                        END IF;

                        E_ERR := '0';
                        WEL := '0';
                        WIP := '0';
                        WVREG := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                    WVREG := '0';
                END IF;

            WHEN    sector_erase_4  | p4_erase_4  =>

                SECTOR := command.sect;
                ADDR := command.addr;

                IF command.cmd = sector_erase_4 THEN
                    opcode_tmp      := I_SE4;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase_4 THEN
                    opcode_tmp      := I_P4E4;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);

                        IF NOT(PARAMETER_ERASE) THEN
                            IF CFR3V(3) = '0' AND TBPARM = '0' THEN
                                IF SECTOR <= 32 THEN
                                    Corrupt_Sec(0) := '0';
                                    erase_mem(32*(SecSize4+1),
                                              SecSize256,
                                              linked_list(0));
                                ELSE
                                    Corrupt_Sec(SECTOR-32) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR-32));
                                END IF;
                            ELSIF CFR3V(3) = '0' AND TBPARM_NV = '1' THEN
                                IF SECTOR >= 511 THEN
                                    Corrupt_Sec(511) := '0';
                                    erase_mem(0,
                                            55*(SecSize4+1)-1,
                                            linked_list(511));
                                ELSE
                                    Corrupt_Sec(SECTOR) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR));
                                END IF;
                            ELSE
                                Corrupt_Sec(SECTOR) := '0';
                                erase_mem(0,
                                        SecSize256,
                                        linked_list(SECTOR));
                            END IF;
                        ELSE
                            IF TBPARM = '1' THEN
                                Corrupt_Sec(511) := '0';
                                erase_mem((SECTOR-200)*(SecSize4+1),
                                        (SECTOR-199)*(SecSize4+1)-1,
                                        linked_list(511));
                            ELSE
                                Corrupt_Sec(0) := '0';
                                erase_mem(SECTOR*(SecSize4+1),
                                        (SECTOR+1)*(SecSize4+1)-1,
                                        linked_list(0));
                            END IF;

                        END IF;

                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                    WVREG := '0';
                END IF;

            WHEN    bulk_erase_60 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_60,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CFR3V(3) = '0' THEN
                                sec_tmp := i / (SecSize256+1);
                                IF TBPARM_NV = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (32*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 32;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 32;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            32*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 32*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize256+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN

                                IF CFR3V(3) = '0' AND  TBPARM = '1' THEN
                                    IF SECTOR = 511 THEN
                                        Corrupt_Sec(511) := '0';
                                        erase_mem(0,
                                                55*(SecSize4+1)-1,
                                                linked_list(511));
                                    ELSIF SECTOR > 511 THEN
                                        Corrupt_Sec(511) := '0';
                                        erase_mem((SECTOR-200)*(SecSize4+1),
                                                (SECTOR-199)*(SecSize4+1)-1,
                                                linked_list(511));
                                    ELSE
                                        Corrupt_Sec(SECTOR) := '0';
                                        erase_mem(0,
                                                SecSize256,
                                                linked_list(SECTOR));
                                    END IF;
                                ELSIF CFR3V(3) = '0' AND TBPARM_NV = '0' THEN
                                    IF SECTOR = 32 THEN
                                        Corrupt_Sec(0) := '0';
                                        erase_mem(32*(SecSize4+1),
                                                SecSize256,
                                                linked_list(0));
                                    ELSIF SECTOR < 32 THEN
                                        Corrupt_Sec(0) := '0';
                                        erase_mem(SECTOR*(SecSize4+1),
                                                (SECTOR+1)*(SecSize4+1)-1,
                                                linked_list(0));
                                    ELSE
                                        Corrupt_Sec(SECTOR-32) := '0';
                                        erase_mem(0,
                                                SecSize256,
                                                linked_list(SECTOR-32));
                                    END IF;
                                ELSE
                                    Corrupt_Sec(SECTOR) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR));
                                END IF;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WVREG := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN    bulk_erase_C7 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_C7,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CFR3V(3) = '0' THEN
                                sec_tmp := i / (SecSize256+1);
                                IF TBPARM_NV = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (32*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 32;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 32;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            32*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 32*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize256+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN

                                IF CFR3V(3) = '0' AND  TBPARM = '1' THEN
                                    IF SECTOR = 511 THEN
                                        Corrupt_Sec(511) := '0';
                                        erase_mem(0,
                                                55*(SecSize4+1)-1,
                                                linked_list(511));
                                    ELSIF SECTOR > 511 THEN
                                        Corrupt_Sec(511) := '0';
                                        erase_mem((SECTOR-200)*(SecSize4+1),
                                                (SECTOR-199)*(SecSize4+1)-1,
                                                linked_list(511));
                                    ELSE
                                        Corrupt_Sec(SECTOR) := '0';
                                        erase_mem(0,
                                                SecSize256,
                                                linked_list(SECTOR));
                                    END IF;
                                ELSIF CFR3V(3) = '0' AND TBPARM_NV = '0' THEN
                                    IF SECTOR = 32 THEN
                                        Corrupt_Sec(0) := '0';
                                        erase_mem(32*(SecSize4+1),
                                                SecSize256,
                                                linked_list(0));
                                    ELSIF SECTOR < 32 THEN
                                        Corrupt_Sec(0) := '0';
                                        erase_mem(SECTOR*(SecSize4+1),
                                                (SECTOR+1)*(SecSize4+1)-1,
                                                linked_list(0));
                                    ELSE
                                        Corrupt_Sec(SECTOR-32) := '0';
                                        erase_mem(0,
                                                SecSize256,
                                                linked_list(SECTOR-32));
                                    END IF;
                                ELSE
                                    Corrupt_Sec(SECTOR) := '0';
                                    erase_mem(0,
                                            SecSize256,
                                            linked_list(SECTOR));
                                END IF;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WVREG := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN     ers_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN     ers_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN    csneg_zero   =>

                bus_cycle(bus_cmd => bus_select);

                WAIT FOR command.wtime;

                bus_cycle(bus_cmd => bus_deselect);

            WHEN     dp_down    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DPD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

            WHEN    pg_prog      =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CFR3V(3),TBPARM_NV, SPARM_NV);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);

                            READ_DATA(page_addr/(SecSize256+1),
                                     page_addr MOD (SecSize256+1)+i-cnt,
                                     mem_data);

                            IF mem_data>-1 THEN
                                slv_2 := to_slv(mem_data,8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            WRITE_DATA(page_addr/(SecSize256+1),
                                       page_addr MOD(SecSize256+1) + i- cnt,
                                       to_nat(slv_1));

                            IF ADDR + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                ADDR := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        IF ES = '0' THEN
                            WEL := '0';
                            WVREG := '0';
                        END IF;
                        WIP := '0';
                    ELSE
                        P_ERR := '1';
                        WIP := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    pg_prog4      =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP4,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CFR3V(3),TBPARM_NV, SPARM_NV);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);
                            READ_DATA(page_addr/(SecSize256+1),
                                     page_addr MOD (SecSize256+1)+i-cnt,
                                     mem_data);

                            IF mem_data > -1 THEN
                                slv_2 := to_slv(mem_data,8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            WRITE_DATA(page_addr/(SecSize256+1),
                                       page_addr MOD(SecSize256+1) + i- cnt,
                                       to_nat(slv_1));

                            IF ADDR + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                ADDR := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        WEL   := '0';
                        WVREG := '0';
                        WIP   := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN     prg_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN     prg_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN    otp_prog      =>

                ADDR        := command.addr;
                Data_byte   := command.data1;
                Byte_number := command.byte_num;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPP,
                          address => command.addr,
                          sector  => 0,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_OTPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                LOCK_BYTE1 := to_slv(Otp(16#10#),8);
                LOCK_BYTE2 := to_slv(Otp(16#11#),8);
                LOCK_BYTE3 := to_slv(Otp(16#12#),8);
                LOCK_BYTE4 := to_slv(Otp(16#13#),8);

                IF status /= err AND WEL = '1' AND FREEZE = '0' THEN
                    WIP := '1';
                    IF ADDR + (Byte_number - 1) <= OTPHiAddr THEN
                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            slv_1 := to_slv(Data_byte,8);

                            IF Otp(ADDR + i)>-1 THEN
                                slv_2 := to_slv(Otp(ADDR + i),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            Otp(ADDR + i) := to_nat(slv_1);

                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                    ELSE
                        ASSERT false
                            REPORT "Programming will reach over address "&
                            " limit of OTP array"
                            SEVERITY warning;
                    END IF;
                    P_ERR := '0';
                    WEL   := '0';
                    WVREG := '0';
                    WIP   := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

            WHEN    otp_read      =>
            
                IF sdf_max_param30 THEN
                    half_period := half_period_30pF;
                END IF;
                
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_OTPR,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_OTPR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_nvldr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_PNVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_PNVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    IF to_nat(NVDLR_reg) > -1 THEN
                        slv_2 := NVDLR_reg;
                    ELSE
                        slv_2 := (OTHERS=>'X');
                    END IF;

                    IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                        NVDLR_reg := slv_1;
                        VDLR_reg  := slv_1;
                    END IF;

                    WEL := '0';
                    WVREG := '0';
--                     VDLR_reg  := NVDLR_reg; --???
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_wvdlr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_WVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_WVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    VDLR_reg  := slv_1;
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_autoboot      =>

                WIP := '1';
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ABWR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_ABWR,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                slv_3 := to_slv(command.data1, 16);
                slv_4 := to_slv(command.data2, 16);

                IF status /= err AND WEL = '1' THEN
                    AutoBoot_reg := slv_3(7 downto 0) & slv_3(15 downto 8)&
                                    slv_4(7 downto 0) & slv_4(15 downto 8);

                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_asp      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ASPP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_ASPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' AND (PWDMLB = '1' AND
                   PSTMLB = '1') THEN

                    slv_3 := to_slv(command.data1, 16);

                    IF DYBLBB = '1' THEN
                        DYBLBB := slv_3(4);
                    END IF;

                    IF PPBOTP = '1' THEN
                        PPBOTP    := slv_3(3);
                    END IF;

                    IF PERMLB = '1' THEN
                        PERMLB    := slv_3(0);
                    END IF;

                    IF (slv_3(2) = '0' AND slv_3(1) = '0') THEN
                        P_ERR := '1';
                        WIP   := '1';
                    ELSE
                        PWDMLB    := slv_3(2);
                        PSTMLB    := slv_3(1);
                    END IF;

                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_password      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    Password_reg := to_slv(command.data4, 16)&
                                    to_slv(command.data3, 16)&
                                    to_slv(command.data2, 16)&
                                    to_slv(command.data1, 16);
                    WIP := '0';
                    WEL := '0';
                    WVREG := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    psw_unlock      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSU,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSU,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err THEN
                    Pass_tmp := to_slv(command.data4, 16)&
                                to_slv(command.data3, 16)&
                                to_slv(command.data2, 16)&
                                to_slv(command.data1, 16);
                    IF Pass_tmp = Password_reg  AND PWDMLB = '0' THEN
                        PPB_LOCK := '1';
                        WEL      := '0';
                        WVREG := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbl_reg_rd       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PLBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PLBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_ppbl_reg       =>

                half_period := half_period3_srl;

                WIP := '1';

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBWR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    PPB_LOCK := '0';
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbacc_rd       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PPBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ppbacc_rd4       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_PPBRD4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    w_ppb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_ppb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WVREG := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    ppb_ers  =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBERS,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits:= (OTHERS => '1');
                    WEL   := '0';
                    WVREG := '0';
                ELSE
                    E_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    dybacc_rd       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DYBRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dybacc_rd4       =>

                half_period := half_period2_srl;

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DYBRD4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_dyb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

            WHEN    w_dyb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                    WVREG := '0';
                END IF;

            WHEN    ecc_read       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_REDUS,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_REDUS,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_REDUS,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_REDUS,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ecc_read4       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_REDUS4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_REDUS4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_REDUS4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_REDUS4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    wt          =>
                WAIT FOR command.wtime;
                WAIT for 50 ns;
                
--             WHEN    CSneg_pulse          =>
--                 CSNeg := '0';
--                 WAIT FOR command.wtime;
--                 CSNeg := '1';


            WHEN    inv_write          =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_inv_write,
                          data_num=> command.byte_num,
                          opcode  => to_slv(command.data1,8));

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF BP0 = '0' AND BP1 = '0' AND BP2 = '0' THEN
                        FOR i IN 0 TO SecNumHyb LOOP
                            Corrupt_Sec(i) := '0';
                            erase_mem(0,
                                      SecSize256,
                                      linked_list(i));
                        END LOOP;
                        E_ERR := '0';
                    ELSE
                        E_ERR := '0';
                    END IF;
                    WEL := '0';
                    WVREG := '0';
                END IF;
                
            WHEN    seerc_rd  =>

                SECTOR := command.sect;
                ADDR := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_SEERC,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_SEERC,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        sesa(AddrLow,AddrHigh,SECTOR);

                        E_ERR := '0';
                        WEL   := '0';
                        WIP   := '0';
                    ELSE
                        E_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WEL := '0';
                END IF;
                
            WHEN    assert_cs  =>

                tm      := command.wtime;

                bus_cycle(bus_cmd => bus_select);
--                     WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect);
            
            WHEN    jedec_reset  =>

                tm                  := command.wtime;
                jedec_reset_active  <= '1';
                -- First CS# assertion
                T_SI    <= '0';

                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                -- Wait for CS# deassertion hold time
                WAIT FOR tm;

                -- Second CS# assertion
                T_SI    <= '1';
                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                -- Wait for CS# deassertion hold time
                WAIT FOR tm;

                -- Third CS# assertion
                T_SI    <= '0';
                WAIT FOR tcss;
                bus_cycle(bus_cmd => bus_select_no_clock);
                WAIT FOR tm;
                bus_cycle(bus_cmd => bus_deselect_no_clock);

                jedec_reset_active  <= '0';

            WHEN    OTHERS  =>  null;
        END CASE;

    END PROCEDURE;

    VARIABLE cmd_cnt    :   NATURAL;
    VARIABLE command    :   cmd_rec;

BEGIN
    TestInit(TimingModel, LongTimming);
    Pick_TC (Model   =>  "s25hs01gt");

    Tseries <=  ts_cnt  ;
    Tcase   <=  tc_cnt  ;

    Generate_TC
        (Model       => TimingModel ,
         Series      => ts_cnt,
         TestCase    => tc_cnt,
         Sec_Arch    => BootConfig,
         command_seq => cmd_seq);

    cmd_cnt := 1;
    WHILE cmd_seq(cmd_cnt).cmd /= done LOOP
        command  := cmd_seq(cmd_cnt);
        status   <=  command.status;
        cmd      <=  command.cmd;
        read_num <= command.byte_num;
        cmd_dc(command);
        cmd_cnt :=cmd_cnt +1;
    END LOOP;

END PROCESS tb;

-------------------------------------------------------------------------------
-- Checker process,
-------------------------------------------------------------------------------
checker: PROCESS
    VARIABLE Addr_reg    : std_logic_vector(31 downto 0);
    VARIABLE RDAR_reg    : std_logic_vector(7 downto 0);
    VARIABLE Data_reg    : std_logic_vector(63 downto 0);
    VARIABLE DLP0_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP1_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP2_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP3_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP_ACT     : std_logic_vector(1 downto 0);
    VARIABLE DLP_EN      : std_logic;
    VARIABLE Pass_out    : std_logic_vector(63 downto 0);
    VARIABLE address     : NATURAL RANGE 0 TO AddrRANGE+1;
    VARIABLE byte        : NATURAL;
    VARIABLE IDLength    : NATURAL RANGE 16#00# TO 16#0F#;
    VARIABLE SFDPaddress : NATURAL RANGE 16#0000# TO 16#0247#;
    VARIABLE tmp         : NATURAL;
    VARIABLE Lat_cnt     : NATURAL;
    VARIABLE Reg_Lat_cnt : NATURAL;
    VARIABLE Sec_addr    : NATURAL RANGE 0 TO SecSize256;
    VARIABLE SecAddr     : NATURAL RANGE 0 TO AddrRANGE;
    VARIABLE AutoBoot_reg_rd : std_logic_vector(31 downto 0);

BEGIN

    IF (T_CSNeg='0') THEN
        DLP_EN := '0';
        DLP0_reg(7 downto 0) := (OTHERS => '0');
        DLP1_reg(7 downto 0) := (OTHERS => '0');
        DLP2_reg(7 downto 0) := (OTHERS => '0');
        DLP3_reg(7 downto 0) := (OTHERS => '0');

        --Opcode
        IF (status /= rd_cont_dualIO AND status /= rd_cont_dualIO4 AND
            status /= rd_cont_quadIO AND status /= rd_cont_quadIO4 AND
            status /= rd_cont_qddr   AND status /= rd_cont_qddr4   AND
            status /= none AND status /= read_fast_4_IO) THEN
            IF QPI='1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            ELSE
                FOR I IN 7 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            END IF;
        END IF;

        --Address
        --3 Bytes Address
        IF (QPI='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CFR2V(7) = '0') OR
             cmd = read_SFDP) THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_IO3RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CFR2V(7) = '0') OR cmd = read_SFDP THEN
            FOR I IN 23 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = dual_high_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 11 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(23-2*i) := T_SO;
                Addr_reg(22-2*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 23 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_rd AND CFR2V(7) = '0' THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_IO3RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_ddr_rd AND CFR2V(7)= '0' THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(23)   := T_IO3RESETNeg;
            Addr_reg(22)   := T_WPNeg;
            Addr_reg(21)   := T_SO;
            Addr_reg(20)   := T_SI;
            FOR I IN 1 TO 5 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(23-4*i)   := T_IO3RESETNeg;
                Addr_reg(22-4*i)   := T_WPNeg;
                Addr_reg(21-4*i)   := T_SO;
                Addr_reg(20-4*i)   := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --4 Bytes Address
        IF (QPI='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CFR2V(7)='1') OR
             cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4) THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_IO3RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CFR2V(7)='1') OR cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4 THEN
            FOR I IN 31 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = dual_high_rd AND CFR2V(7)='1') OR cmd = dual_high_rd_4 THEN
            FOR I IN 0 TO 15 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(31-2*i) := T_SO;
                Addr_reg(30-2*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_rd AND CFR2V(7) = '1') OR cmd = quad_rd_4 THEN
            FOR I IN 0 TO 31 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_rd AND CFR2V(7)='1') OR cmd = quad_high_rd_4 THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_IO3RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_ddr_rd AND CFR2V(7) = '1') OR
               cmd = quad_high_ddr_rd_4 THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(31)   := T_IO3RESETNeg;
            Addr_reg(30)   := T_WPNeg;
            Addr_reg(29)   := T_SO;
            Addr_reg(28)   := T_SI;
            FOR I IN 1 TO 7 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(31-4*i)   := T_IO3RESETNeg;
                Addr_reg(30-4*i)   := T_WPNeg;
                Addr_reg(29-4*i)   := T_SO;
                Addr_reg(28-4*i)   := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --Mode Byte
        
        IF cmd = fast_rd4 THEN
            IF QPI = '1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSE
                FOR I IN 7 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = dual_high_rd OR cmd = dual_high_rd_4 THEN
            IF QPI = '1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSE
                FOR I IN 3 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = quad_high_rd OR cmd = quad_high_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL T_SCK'EVENT;
            END LOOP;
        END IF;

        -- Dummy Bytes
        IF cmd = read_SR1 OR cmd = read_JID OR
        (( cmd = read_SR2 OR cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
         AND QPI = '0') OR
        (( cmd = read_JQID) AND QPI = '1') THEN
        Reg_Lat_cnt := to_nat(CFR3V(7)) + to_nat(CFR3V(7))*to_nat(CFR3V(6));
        ELSIF (( cmd = read_SR2 OR cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
         AND QPI = '1') OR cmd = rdar_read OR cmd = dybacc_rd4 OR cmd = dybacc_rd THEN
        Reg_Lat_cnt := to_nat(CFR3V(7)) + to_nat(CFR3V(6));
        END IF;
        
        Lat_cnt := to_nat(CFR2V(3 DOWNTO 0));
--         Reg_Lat_cnt := to_nat(CFR3V(7 DOWNTO 6));
        IF cmd = read_SFDP THEN
            FOR I IN 7 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF cmd = read_RUID THEN
            FOR I IN 31 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF (cmd = fast_rd OR cmd = otp_read OR 
              cmd = ecc_read OR cmd = ecc_read4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
--                     IF sdf_max_param THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END LOOP;
            END IF;
        ELSIF (cmd = rdar_read) THEN
          IF Addr_reg(23 downto 16) >= "10000000" THEN
                IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
                END IF; 
          ELSE 
                IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
                END IF;
          END IF;
        ELSIF (cmd = dual_high_rd OR cmd = dual_high_rd_4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period/2;
                        END IF;
                END LOOP;
            END IF;

        ELSIF (cmd = read_SR2 OR cmd = read_CR1 OR
             cmd = rd_dlp OR cmd = pass_reg_rd OR
             cmd = ppbl_reg_rd OR
             cmd = dybacc_rd OR cmd = dybacc_rd4) THEN
            IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF ( cmd = ppbacc_rd OR cmd = ppbacc_rd4) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;

        ELSIF (cmd = read_SR1) THEN
            IF Reg_Lat_cnt >= 1 THEN
                FOR I IN Reg_Lat_cnt-1 DOWNTO 0 LOOP
   
                    WAIT UNTIL rising_edge(T_SCK);
                    WAIT FOR 1 ns;

                END LOOP;
            END IF;
--         ELSIF cmd = fast_rd4 AND QPI = '0' THEN
--            IF Lat_cnt >= 1 THEN
--                 FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
--                     WAIT UNTIL rising_edge(T_SCK);
--                     IF sdf_max_param THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
--                 END LOOP;
--             END IF;
        ELSIF cmd = fast_rd4 AND QPI = '0' THEN
        IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
        ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                            WAIT FOR 10 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2.5 ns;
                            END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SO;
                            DLP2_reg(7) := T_SO;
                            DLP3_reg(7) := T_SO;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                          WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SO;
                            DLP2_reg(I) := T_SO;
                            DLP3_reg(I) := T_SO;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SO;
                            DLP2_reg(7) := T_SO;
                            DLP3_reg(7) := T_SO;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SO;
                            DLP2_reg(I) := T_SO;
                            DLP3_reg(I) := T_SO;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
                        IF (sdf_max_param = TRUE) THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                        END IF;
                END IF;
                DLP_EN := '1';
          END IF;
        ELSIF cmd = fast_rd4 AND QPI = '1' THEN
          IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param30 THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
          ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    WAIT FOR 3.1 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2 ns;
                            END IF;
                    IF (VDLR_reg /= "00000000") THEN
                      IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period;
                     END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                          WAIT FOR 3.1 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 2 ns;
                            END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                         IF (sdf_max_param = TRUE) THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;
        ELSIF ((cmd = quad_high_rd or cmd = quad_high_rd_4) AND QPI = '0') THEN
            IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                           
                           
                           DebugB := 2;
                           IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 3*half_period;
                           ELSE
                                WAIT FOR 9.1 ns;
                           END IF;
--                         IF sdf_max_param THEN
--                             WAIT FOR half_period;
-- --                             WAIT FOR half_period/2;
--                          END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                          IF sdf_max_param = TRUE THEN
                              WAIT UNTIL  falling_edge(T_SCK);
                          ELSE
                              WAIT UNTIL  rising_edge(T_SCK);
                          END IF;
                          IF sdf_max_param30 = FALSE THEN
                              WAIT FOR 3.1 ns;
                          END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            IF sdf_max_param30 THEN
-- --                             WAIT FOR half_period;
                                 WAIT FOR 0 ns;
                            END IF;
                            DebugB := 0;
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                         IF (sdf_max_param = TRUE) THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;
          
        ELSIF (cmd = quad_rd_4 OR cmd = quad_rd
               OR cmd = quad_high_rd OR
                cmd = quad_high_rd_4 ) THEN
            IF Lat_cnt >= 1 AND Lat_cnt <8 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                    IF sdf_max_param THEN
                            WAIT FOR half_period;
                            WAIT FOR half_period/2;
                     END IF;
                END LOOP;
            ELSIF Lat_cnt >= 8 THEN
                IF Lat_cnt = 8 THEN
                    
                    IF (VDLR_reg /= "00000000") THEN
                           IF sdf_max_param = TRUE THEN
                                WAIT FOR 2*half_period;
                           ELSE
                                WAIT FOR 0.7 ns;
                           END IF;
                           IF sdf_max_param30 = TRUE  THEN
                                 WAIT FOR 5.2 ns;
                           ELSIF sdf_max_param15 = TRUE  THEN
                                WAIT FOR 5.2 ns; 
                           ELSE
                                WAIT FOR 8.4 ns;
                           END IF;
--                         IF sdf_max_param THEN
--                             WAIT FOR half_period;
-- --                             WAIT FOR half_period/2;
--                          END IF;
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                          WAIT UNTIL  rising_edge(T_SCK);
                          IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 5.5 ns;
                          ELSE
                                WAIT FOR 3.1 ns;
                          END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            IF sdf_max_param THEN
-- --                             WAIT FOR half_period;
                            WAIT FOR 1 ns;
                            END IF;
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
               
                ELSIF Lat_cnt > 8 THEN
                    FOR I IN Lat_cnt-9 DOWNTO 0 LOOP      
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(7) := T_SO;
                            DLP1_reg(7) := T_SI;
                            DLP2_reg(7) := T_WPNeg;
                            DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL  rising_edge(T_SCK);
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL rising_edge(T_SCK);
--                         IF (sdf_max_param = TRUE) THEN
--                             WAIT FOR half_period;
--                             WAIT FOR half_period/2;
--                         END IF;
                END IF;
                DLP_EN := '1';
          END IF;          
                    
        
                
        ELSIF cmd = quad_high_ddr_rd THEN
            IF Lat_cnt >= 1 AND Lat_cnt < 4 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 4 THEN
                IF Lat_cnt = 4 THEN
                    WAIT FOR 6.1 ns;
                    IF (VDLR_reg /= "00000000") THEN
                        DLP0_reg(7) := T_SO;
                        DLP1_reg(7) := T_SI;
                        DLP2_reg(7) := T_WPNeg;
                        DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 6.1 ns;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                ELSE
                    FOR I IN (Lat_cnt-5) DOWNTO 0 LOOP
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    IF (VDLR_reg /= "00000000") THEN
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    FOR I IN 7 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        IF (sdf_max_param = TRUE) THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                END IF;
                DLP_EN := '1';
            END IF;
        ELSIF cmd = quad_high_ddr_rd_4 THEN
            IF Lat_cnt >= 1 AND Lat_cnt < 4 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 4 THEN
                IF Lat_cnt = 4 THEN
                    WAIT FOR 6.1 ns;
                    IF (VDLR_reg /= "00000000") THEN
                        DLP0_reg(7) := T_SO;
                        DLP1_reg(7) := T_SI;
                        DLP2_reg(7) := T_WPNeg;
                        DLP3_reg(7) := T_IO3RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 6.1 ns;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                ELSE
                    FOR I IN (Lat_cnt-5) DOWNTO 0 LOOP
                        WAIT UNTIL rising_edge(T_SCK);
                         WAIT FOR 0.1 ns;
                    END LOOP;
                    IF (VDLR_reg /= "00000000") AND sdf_min_param = FALSE THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        IF sdf_max_param30 THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                        IF sdf_max_param15 THEN
--                             WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                    END IF;
                    FOR I IN 7 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                            IF (sdf_min_param) THEN
                                WAIT FOR 2 ns;
                            ELSIF (sdf_max_param15) THEN
                                WAIT FOR 1.2 ns;
                            ELSIF (sdf_max_param) THEN
                                WAIT FOR 0.8 ns;
                            ELSE
                                WAIT FOR 0.3 ns;
                            END IF;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_IO3RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                IF (VDLR_reg = "00000000") THEN
                    WAIT UNTIL falling_edge(T_SCK);
                        IF sdf_max_param THEN
                            WAIT FOR half_period_ddr;
                            WAIT FOR half_period_ddr/2;
                        END IF;
                END IF;
                DLP_EN := '1';
            END IF;
        END IF;

        --Data Bytes
        IDLength  := 16#00#;
        SFDPaddress := 16#00#;
        byte        := 0;

        IF (status /= none AND status /= err) THEN
            IF (sdf_max_param = TRUE) AND 
               (cmd = quad_high_rd OR cmd = quad_high_rd_4) 
                     AND (VDLR_reg = "00000000") AND  QPI = '0' THEN
                            WAIT FOR 2*half_period;
--                             WAIT FOR half_period/2;
             END IF;
         
            FOR I IN read_num-1 DOWNTO 0 LOOP
                Data_reg(7 downto 0) := (OTHERS => '0');
                IF (cmd = dual_high_rd OR cmd = dual_high_rd_4) AND
                   QPI = '0' THEN
                    FOR J IN 0 TO 3 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 5.2 ns;
                            ELSE
                                WAIT FOR 4.3 ns;
                            END IF;
                        ELSIF half_period = half_period_30pF THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            WAIT FOR 4.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-2*J) := T_SO;
                        Data_reg(6-2*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_rd OR cmd = quad_rd_4 THEN
                    FOR J IN 0 TO 1 LOOP
                         IF half_period = half_period3_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                         ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                                IF sdf_max_param = TRUE THEN
                                    WAIT FOR 7.51 ns;
                                ELSIF sdf_min_param = TRUE THEN 
                                    WAIT FOR 2 ns;
                                ELSE
                                    WAIT FOR 5.5 ns;
                                END IF;
                          END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = quad_high_rd OR cmd = quad_high_rd_4) AND QPI = '0' THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            IF MAX30 = '1' AND sdf_min_param = FALSE THEN
                                WAIT UNTIL (falling_edge(T_SCK) OR rising_edge(T_SCK));
                                WAIT FOR 5.3 ns;
                            ELSIF sdf_max_param30 = TRUE THEN
                                WAIT UNTIL rising_edge(T_SCK);
                                WAIT FOR 5.3 ns;
                            ELSE
                                WAIT UNTIL (rising_edge(T_SCK));
                                WAIT FOR 2.3 ns;
                            END IF;
                        ELSIF half_period = half_period_30pF THEN
--                             WAIT FOR 2*half_period;
                                WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                                WAIT FOR 4.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF ((cmd = quad_high_rd OR cmd = quad_high_rd_4) AND QPI = '1')  OR
                      cmd = read_JQID THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF sdf_max_param30 = TRUE THEN
                                WAIT FOR 5.3 ns;
                            ELSE
                                WAIT FOR 4.3 ns;
                            END IF;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF sdf_max_param AND (VDLR_reg /= "00000000") THEN
                                WAIT FOR 7.5 ns;
                            ELSE
                                WAIT FOR 8.1 ns;
                            END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_ddr_rd THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        DebugB := 1;
                        IF NOT sdf_max_param15 THEN
                               WAIT FOR 0.2 ns;
                        END IF;
                        IF sdf_max_param30 THEN
                             WAIT FOR 0.5 ns;
                        DebugB := 0;
                        END IF;

                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_ddr_rd_4 THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        IF not sdf_max_param THEN
                             WAIT FOR 0.5 ns;
                        END IF;

                        --IF not (sdf_min_param OR sdf_max_param) THEN
                        --     WAIT FOR 1.5 ns;
                        --END IF; 
                        IF (VDLR_reg = "00000000") THEN
                            IF sdf_max_param THEN
                                WAIT FOR 0.25 ns;
                            END IF;
                        ELSE
                             DebugB := 1;
                             WAIT FOR 1 ns;
                             
                             IF sdf_max_param15 THEN
                                WAIT FOR 0.5 ns;
                            END IF;
                            DebugB := 0;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = pass_reg_rd AND QPI = '0' THEN
                    FOR J IN 63 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '0' AND Addr_reg(23 downto 20) = "0000"  THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.8 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF sdf_max_param THEN
                            WAIT FOR 4.3 ns;
                            ELSE
                                WAIT FOR 5.2 ns;
                            END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '1' AND Addr_reg(23 downto 20) = "0000" THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4 ns;
                         IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 0.5 ns;
                         END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '0' AND Addr_reg(23 downto 20) = "1000"  THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.5 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = rdar_read AND QPI = '1' AND Addr_reg(23 downto 20) = "1000" THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.5 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = read_SFDP OR cmd = read_RUID) AND QPI = '1' THEN
                     FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                     END LOOP;
                ELSIF (cmd = read_SR1 AND QPI = '0') THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (cmd = read_SR2  AND QPI = '0') THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
--                             IF CFR3V(7 DOWNTO 6) = "00" THEN
                           
                            WAIT FOR 2.3 ns;

--                             END IF;
                            IF sdf_min_param = FALSE THEN
                                WAIT FOR 1.5 ns;
                            END IF;
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                                END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (cmd = read_SR1 AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                            IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 1 ns;
   
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                                END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = read_SR2 AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            
                            WAIT FOR 7.3 ns;
                            IF sdf_max_param = TRUE THEN
                                WAIT FOR half_period;
                            END IF;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF ( cmd = read_JID OR cmd = read_JQID OR
                      (( cmd = read_CR1 OR cmd = rd_dlp OR cmd = ppbl_reg_rd) 
                          AND QPI = '0')) THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
--                             IF CFR3V(7 DOWNTO 6) = "00" THEN
                          
                            WAIT FOR 2.3 ns;

--                             END IF;
                        ELSIF half_period = half_period_30pF THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            WAIT FOR 2.3 ns;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF sdf_min_param THEN
                            WAIT FOR 2 ns;
                            ELSIF sdf_max_param THEN
                            WAIT FOR 7.51 ns;
                            IF sdf_max_param30 = TRUE  THEN
                               WAIT FOR 0.5 ns;
                            END IF;
                            ELSE
                            WAIT FOR 5.5 ns;
                            END IF;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF (( cmd = read_CR1) AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (  cmd = rd_dlp AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2.8 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (( cmd = ppbl_reg_rd OR 
                      cmd = dybacc_rd OR cmd = ppbacc_rd OR
                      cmd = dybacc_rd4 OR cmd = ppbacc_rd4) AND QPI = '1') THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 3.8 ns;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));

                            WAIT FOR 2.8 ns;

                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF QPI = '1' AND cmd = otp_read THEN
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF (cmd = fast_rd  OR cmd = fast_rd4) AND QPI = '0' THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 2;
                            WAIT FOR 2.5 ns;
                            IF sdf_max_param = TRUE THEN
                               WAIT FOR 0.6 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                               END IF;
                            END IF;
                            DebugB := 0;
                        ELSE
                            WAIT UNTIL (rising_edge(T_SCK));
                            DebugB := 1;
                            IF sdf_min_param = TRUE THEN
                               WAIT FOR 2 ns;
                            ELSE
                               WAIT FOR 2.2 ns;
                            END IF;
                            IF sdf_max_param30 = TRUE  THEN
                                   WAIT FOR 2 ns;
                            END IF;
                            DebugB := 0;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF QPI = '0' THEN
                    FOR J IN 7 DOWNTO 0 LOOP
                        IF half_period = half_period1_srl THEN
                            WAIT UNTIL (rising_edge(T_SCK));
                            IF status /= read_fast_4_IO THEN
                                WAIT FOR 4.3 ns;
                                IF sdf_max_param30 = TRUE  THEN
                                    WAIT FOR 0.692 ns;
                                END IF;
                            ELSE 
                            WAIT FOR 4.3 ns;
                               IF sdf_max_param30 = TRUE  THEN
                                    WAIT FOR 0.692 ns;
                               END IF;
                            END IF;
                        ELSIF half_period = half_period2_srl THEN 
                            WAIT UNTIL (falling_edge(T_SCK));
--                             DebugB := 1;
                            WAIT FOR 8 ns;
--                             DebugB := 0;
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSE
                    FOR J IN 0 TO 1 LOOP
                        IF half_period = half_period1_srl THEN 
                            WAIT UNTIL (rising_edge(T_SCK));
                            WAIT FOR 4.3 ns;
                            IF sdf_max_param30 = TRUE  THEN
                                WAIT FOR 0.692 ns;
                            END IF; 
                        
                        ELSE
                            WAIT UNTIL (falling_edge(T_SCK));
                            WAIT FOR 8 ns;
                        END IF;
                        Data_reg(7-4*J) := T_IO3RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                END IF;

                Rd_Sec := address / (SecSize256+1);
                Rd_Addr:= address - Rd_Sec*(SecSize256+1);

                READ_DATA(Rd_Sec,Rd_Addr,mem_data);

                CASE status IS
                    WHEN read | read_4 | read_fast | read_fast_4 |
                         read_dual_hi | read_dual_hi4| read_quad_hi |
                         read_quad_hi4 | rd_quad | rd_quad_4 | read_ddr_quad_hi |
                         read_ddr_quad_hi4 | rd_cont_dualIO | read_fast_4_IO |
                         rd_cont_dualIO4 | rd_cont_quadIO | rd_cont_quadIO4 |
                         rd_cont_qddr | rd_cont_qddr4 =>
                        DLP_ACT := "00";
                        IF (VDLR_reg /= "00000000") AND DLP_EN = '1' THEN
                            IF (status = read_ddr_quad_hi4
                            OR status = read_ddr_quad_hi OR status = read_fast_4
                            OR status = read_fast_4_IO OR status = read_quad_hi OR 
                            status = read_quad_hi4 OR status = rd_quad OR 
                            status = rd_quad_4 OR status = rd_cont_quadIO OR 
                            status = rd_cont_quadIO4 OR status = rd_cont_qddr 
                            OR status = rd_cont_qddr4) 
                            THEN
                                DLP_ACT := "11";
                            END IF;
                            DLP_EN := '0';
                        END IF;

                        --read memory array data and dlp if enabled
                        Check_read (
                            DQ        => Data_reg(7 downto 0),
                            DQ_reg0   => DLP0_reg(7 downto 0),
                            DQ_reg1   => DLP1_reg(7 downto 0),
                            DQ_reg2   => DLP2_reg(7 downto 0),
                            DQ_reg3   => DLP3_reg(7 downto 0),
                            D_mem     => mem_data,
                            DLP_reg   => to_nat(VDLR_reg),
                            D_dlp_act => DLP_ACT,
                            check_err => check_err);

                        IF CFR4V(4) = '0'  OR status = read OR
                           status = read_4 THEN   --Wrap Disabled
                            -- if the highest address is reached
                            IF address = AddrRange THEN
                                address := 0;
                            ELSE
                                address := address + 1;
                            END IF;
                        ELSE          --Wrap Enabled
                            address := address + 1;

                            IF CFR4V(1 DOWNTO 0)= "01" AND
                               address MOD 16 = 0 THEN
                                address:= address - 16;
                            ELSIF CFR4V(1 DOWNTO 0) = "10" AND
                               address MOD 32 = 0 THEN
                                address:= address - 32;
                            ELSIF CFR4V(1 DOWNTO 0) = "11" AND
                               address MOD 64 = 0 THEN
                                address:= address - 64;
                            ELSIF CFR4V(1 DOWNTO 0) = "00" AND
                               address MOD 8 = 0 THEN
                                address:= address - 8;
                            END IF;
                        END IF;

                    WHEN rd_HiZ =>
                        --read memory array data
                        Check_Z (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN rd_U =>
                        --read memory array data
                        Check_X (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN read_otp =>
                        --read otp array data
                        IF address >= OTPLoAddr AND address <= OTPHiAddr THEN
                            Check_otp_read (
                                DQ         => Data_reg(7 downto 0),
                                otp_mem    => Otp(address),
                                check_err  => check_err);

                            address := address +1;
                        END IF;

                    WHEN rd_JID | rd_JQID =>

                        IF (IDLength <= 16#0F#) THEN
                            -- read ID
                            Check_read_JID (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => to_nat(MDID_reg(8*IDLength + 7 downto 8*IDLength)),
                                byte_no     => byte,
                                check_err   => check_err);

                            IDLength := IDLength + 1;
                         END IF;

                         byte := byte + 1;

                    WHEN rd_SFDP =>

                        --IF (address < SFDPHiAddr-27) THEN
                        IF (address < SFDPHiAddr+1) THEN
                            -- read ID
                            Check_read_SFDP (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => SFDP_array(address) ,
                                check_err   => check_err);
                         END IF;

                         address := address + 1;

                    WHEN rd_SR1 =>
                        --read status register1
                        Check_read_sr1 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(STR1V),
                            check_err=> check_err);

                    WHEN rd_SR2 =>
                        --read status register2
                        Check_read_sr2 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(STR2V),
                            check_err=> check_err);

                    WHEN read_rdar =>
                        --read all registers

                        IF address = 16#00000000# THEN
                            RDAR_reg := STR1N;
                        ELSIF address = 16#00000002# THEN
                            RDAR_reg := CFR1N;
                        ELSIF address = 16#00000003# THEN
                            RDAR_reg := CFR2N;
                        ELSIF address = 16#00000004# THEN
                            RDAR_reg := CFR3N;
                        ELSIF address = 16#00000005# THEN
                            RDAR_reg := CFR4N;
                        ELSIF address = 16#00000010# THEN
                            RDAR_reg := NVDLR_reg;
                        ELSIF address = 16#00000020# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(7 DOWNTO 0);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000021# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(15 DOWNTO 8);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000022# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(23 DOWNTO 16);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000023# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(31 DOWNTO 24);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000024# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(39 DOWNTO 32);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000025# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(47 DOWNTO 40);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000026# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(55 DOWNTO 48);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000027# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(63 DOWNTO 56);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000042# THEN
                            RDAR_reg := AutoBoot_reg(7 DOWNTO 0);
                        ELSIF address = 16#00000043# THEN
                            RDAR_reg := AutoBoot_reg(15 DOWNTO 8);
                        ELSIF address = 16#00000044# THEN
                            RDAR_reg := AutoBoot_reg(23 DOWNTO 16);
                        ELSIF address = 16#00000045# THEN
                            RDAR_reg := AutoBoot_reg(31 DOWNTO 24);
                        ELSIF address = 16#00000030# THEN
                            RDAR_reg := ASP_reg(7 DOWNTO 0);
                        ELSIF address = 16#00000031# THEN
                            RDAR_reg := ASP_reg(15 DOWNTO 8);
                        ELSIF address = 16#00800000# THEN
                            RDAR_reg := STR1V;
                        ELSIF address = 16#00800001# THEN
                            RDAR_reg := STR2V;
                        ELSIF address = 16#00800002# THEN
                            RDAR_reg := CFR1V;
                        ELSIF address = 16#00800003# THEN
                            RDAR_reg := CFR2V;
                        ELSIF address = 16#00800004# THEN
                            RDAR_reg := CFR3V;
                        ELSIF address = 16#00800005# THEN
                            RDAR_reg := CFR4V;
                        ELSIF address = 16#00800010# THEN
                            RDAR_reg := VDLR_reg;
                        ELSIF address = 16#00800091# THEN
                            RDAR_reg := "00000001";
                        ELSIF address = 16#00800095# THEN
                            RDAR_reg := DIC_reg(7 DOWNTO 0);
                        ELSIF address = 16#00800096# THEN
                            RDAR_reg := DIC_reg(15 DOWNTO 8);
                        ELSIF address = 16#00800097# THEN
                            RDAR_reg := DIC_reg(23 DOWNTO 16);
                        ELSIF address = 16#00800098# THEN
                            RDAR_reg := DIC_reg(31 DOWNTO 24);
                        ELSIF address = 16#0080009B# THEN
                            RDAR_reg := PPBL;
                        ELSE
                            RDAR_reg := "XXXXXXXX";
                        END IF;

                        IF RDAR_reg /= "XXXXXXXX" THEN

                            Check_rdar (
                                DQ       => Data_reg(7 downto 0),
                                D_mem    => to_nat(RDAR_reg),
                                check_err=> check_err);
                        ELSE
                            Check_X (
                                DQ        => Data_reg(0),
                                check_err => check_err);
                        END IF;

                    WHEN rd_CR1 =>
                        --read configuration register
                        Check_read_config (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(CFR1V),
                            check_err=> check_err);

                    WHEN read_dlp =>
                        --read dlp register
                        Check_read_dlp (
                            DQ       => Data_reg(7 downto 0),
                            DLP_reg  => to_nat(VDLR_reg),
                            check_err=> check_err);

                    WHEN read_autoboot =>
                        --read autoboot register
                        FOR I IN 0 TO 3 LOOP
                            FOR J IN 0 TO 7 LOOP
                                AutoBoot_reg_rd(I*8+J) :=
                                        AutoBoot_reg((3-I)*8+J);
                            END LOOP;
                        END LOOP;
                        Check_read_autoboot (
                            DQ       => Data_reg(31 downto 0),
                            D_mem    => to_nat(AutoBoot_reg_rd),
                            check_err=> check_err);

                    WHEN read_bank =>
                        --read bank address register
                        Check_read_bank (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(Bank_Addr_reg),
                            check_err=> check_err);

                    WHEN read_pass_reg =>
                        --read password register
                        Pass_out := Password_reg(7  downto 0) &
                                    Password_reg(15 downto 8) &
                                    Password_reg(23 downto 16) &
                                    Password_reg(31 downto 24) &
                                    Password_reg(39 downto 32) &
                                    Password_reg(47 downto 40) &
                                    Password_reg(55 downto 48) &
                                    Password_reg(63 downto 56);

                        Check_read_pass_reg (
                            DQ       => Data_reg(63 downto 0),
                            D_mem    => to_nat(Pass_out),
                            check_err=> check_err);

                    WHEN read_ppbl =>
                        --read ppb lock register
                        Check_read_ppbl (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBL),
                            check_err=> check_err);

                    WHEN read_ppbar | read_ppbar_4 =>
                        --read ppb access register
                        Check_read_ppbar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBAR),
                            check_err=> check_err);

                    WHEN read_ecc | read_ecc_4 =>
                        --read ECC register
                        Check_read_ecc (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(ECC_reg),
                            check_err=> check_err);

                    WHEN read_dybar | read_dybar_4 =>
                        --read dyb access register
                        Check_read_dybar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(DYBAR),
                            check_err=> check_err);

                    WHEN rd_ppblock_0 | rd_ppblock_1 =>
                        Check_PPBLOCK_bit (
                            DQ       => PPBL(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wip_0 | rd_wip_1 =>
                        Check_WIP_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wel_0 | rd_wel_1 =>
                        Check_WEL_bit (
                            DQ       => STR1V(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN erase_succ | erase_nosucc =>
                        Check_eers_bit (
                            DQ       => Data_reg(5),
                            sts      => status,
                            check_err=> check_err);

                    WHEN pgm_succ | pgm_nosucc =>
                        Check_epgm_bit (
                            DQ       => Data_reg(6),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_ps_0 | rd_ps_1 =>
                        Check_PS_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_es_0 | rd_es_1 =>
                        Check_ES_bit (
                            DQ       => Data_reg(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN others =>
                        null;

                END CASE;
            END LOOP;
        END IF;
    END IF;

    WAIT ON T_CSNeg;

END PROCESS checker;

    ---------------------------------------------------------------------------
    ---- SFDP Preload Process
    ---------------------------------------------------------------------------
    SFDPPreload : PROCESS

    BEGIN
        -----------------------------------------------------------------------
        --SFDP Header
        -----------------------------------------------------------------------
        SFDP_array(16#0000#) := 16#53#;
        SFDP_array(16#0001#) := 16#46#;
        SFDP_array(16#0002#) := 16#44#;
        SFDP_array(16#0003#) := 16#50#;
        SFDP_array(16#0004#) := 16#08#;
        SFDP_array(16#0005#) := 16#01#;
        SFDP_array(16#0006#) := 16#03#;
        SFDP_array(16#0007#) := 16#FF#;
        -- 1st Parameter Header
        SFDP_array(16#0008#) := 16#00#;
        SFDP_array(16#0009#) := 16#00#;
        SFDP_array(16#000A#) := 16#01#;
        SFDP_array(16#000B#) := 16#14#;
        SFDP_array(16#000C#) := 16#00#;
        SFDP_array(16#000D#) := 16#01#;
        SFDP_array(16#000E#) := 16#00#;
        SFDP_array(16#000F#) := 16#FF#;
        -- 2nd Parameter Header
        SFDP_array(16#0010#) := 16#84#;
        SFDP_array(16#0011#) := 16#00#;
        SFDP_array(16#0012#) := 16#01#;
        SFDP_array(16#0013#) := 16#02#;
        SFDP_array(16#0014#) := 16#50#;
        SFDP_array(16#0015#) := 16#01#;
        SFDP_array(16#0016#) := 16#00#;
        SFDP_array(16#0017#) := 16#FF#;
        -- 3rd Parameter Header
        SFDP_array(16#0018#) := 16#81#;
        SFDP_array(16#0019#) := 16#00#;
        SFDP_array(16#001A#) := 16#01#;
        SFDP_array(16#001B#) := 16#16#;
        SFDP_array(16#001C#) := 16#C8#;
        SFDP_array(16#001D#) := 16#01#;
        SFDP_array(16#001E#) := 16#00#;
        SFDP_array(16#001F#) := 16#FF#;
        -- 4th Parameter Header
        SFDP_array(16#0020#) := 16#87#;
        SFDP_array(16#0021#) := 16#00#;
        SFDP_array(16#0022#) := 16#01#;
        SFDP_array(16#0023#) := 16#1C#;
        SFDP_array(16#0024#) := 16#58#;
        SFDP_array(16#0025#) := 16#01#;
        SFDP_array(16#0026#) := 16#00#;
        SFDP_array(16#0027#) := 16#FF#;
        -- Unused
        FOR I IN  16#0028# TO 16#00FF# LOOP
           SFDP_array(i) := 16#FF#;
        END LOOP;

        ----------------------------------------------------------------------/
        -- JEDEC Basic Flash Parameters
        ----------------------------------------------------------------------/
        -- DWORD-1
        SFDP_array(16#0100#) := 16#E7#;
        SFDP_array(16#0101#) := 16#20#;
        SFDP_array(16#0102#) := 16#FA#;
        SFDP_array(16#0103#) := 16#FF#;
        -- DWORD-2
        SFDP_array(16#0104#) := 16#FF#;
        SFDP_array(16#0105#) := 16#FF#;
        SFDP_array(16#0106#) := 16#FF#;
        SFDP_array(16#0107#) := 16#3F#;
        -- DWORD-3
        SFDP_array(16#0108#) := 16#48#;
        SFDP_array(16#0109#) := 16#EB#;
        SFDP_array(16#010A#) := 16#08#;
        SFDP_array(16#010B#) := 16#6B#;
        -- DWORD-4
        SFDP_array(16#010C#) := 16#00#;
        SFDP_array(16#010D#) := 16#FF#;
        SFDP_array(16#010E#) := 16#88#;
        SFDP_array(16#010F#) := 16#BB#;
        -- DWORD-5
        SFDP_array(16#0110#) := 16#FE#;
        SFDP_array(16#0111#) := 16#FF#;
        SFDP_array(16#0112#) := 16#FF#;
        SFDP_array(16#0113#) := 16#FF#;
        -- DWORD-6
        SFDP_array(16#0114#) := 16#FF#;
        SFDP_array(16#0115#) := 16#FF#;
        SFDP_array(16#0116#) := 16#00#;
        SFDP_array(16#0117#) := 16#FF#;
        -- DWORD-7
        SFDP_array(16#0118#) := 16#FF#;
        SFDP_array(16#0119#) := 16#FF#;
        SFDP_array(16#011A#) := 16#48#;
        SFDP_array(16#011B#) := 16#EB#;
        -- DWORD-8
        SFDP_array(16#011C#) := 16#0C#;
        SFDP_array(16#011D#) := 16#20#;
        SFDP_array(16#011E#) := 16#00#;
        SFDP_array(16#011F#) := 16#FF#;
        -- DWORD-9
        SFDP_array(16#0120#) := 16#00#;
        SFDP_array(16#0121#) := 16#FF#;
        SFDP_array(16#0122#) := 16#12#;
        SFDP_array(16#0123#) := 16#D8#;
        -- DWORD-10
        SFDP_array(16#0124#) := 16#23#;
        SFDP_array(16#0125#) := 16#FA#;
        SFDP_array(16#0126#) := 16#FF#;
        SFDP_array(16#0127#) := 16#8B#;
        -- DWORD-11
        SFDP_array(16#0128#) := 16#82#;
        SFDP_array(16#0129#) := 16#E7#;
        SFDP_array(16#012A#) := 16#FF#;
        SFDP_array(16#012B#) := 16#E6#;
        -- DWORD-12
        SFDP_array(16#012C#) := 16#EC#;
        SFDP_array(16#012D#) := 16#03#;
        SFDP_array(16#012E#) := 16#1C#;
        SFDP_array(16#012F#) := 16#60#;
        -- DWORD-13
        SFDP_array(16#0130#) := 16#8A#;
        SFDP_array(16#0131#) := 16#85#;
        SFDP_array(16#0132#) := 16#7A#;
        SFDP_array(16#0133#) := 16#75#;
        -- DWORD-14
        SFDP_array(16#0134#) := 16#F7#;
        SFDP_array(16#0135#) := 16#66#;
        SFDP_array(16#0136#) := 16#80#;
        SFDP_array(16#0137#) := 16#5C#;
        -- DWORD-15
        SFDP_array(16#0138#) := 16#8C#;
        SFDP_array(16#0139#) := 16#D6#;
        SFDP_array(16#013A#) := 16#DD#;
        SFDP_array(16#013B#) := 16#FF#;
        -- DWORD-16
        SFDP_array(16#013C#) := 16#F9#;
        SFDP_array(16#013D#) := 16#38#;
        SFDP_array(16#013E#) := 16#F8#;
        SFDP_array(16#013F#) := 16#A1#;
        -- DWORD-17
        SFDP_array(16#0140#) := 16#00#;
        SFDP_array(16#0141#) := 16#00#;
        SFDP_array(16#0142#) := 16#00#;
        SFDP_array(16#0143#) := 16#00#;
        -- DWORD-18
        SFDP_array(16#0144#) := 16#00#;
        SFDP_array(16#0145#) := 16#00#;
        SFDP_array(16#0146#) := 16#BC#;
        SFDP_array(16#0147#) := 16#00#;
        -- DWORD-19
        SFDP_array(16#0148#) := 16#00#;
        SFDP_array(16#0149#) := 16#00#;
        SFDP_array(16#014A#) := 16#00#;
        SFDP_array(16#014B#) := 16#00#;
        -- DWORD-20
        SFDP_array(16#014C#) := 16#F7#;
        SFDP_array(16#014D#) := 16#F5#;
        SFDP_array(16#014E#) := 16#FF#;
        SFDP_array(16#014F#) := 16#FF#;

        -- JEDEC 4-Byte Address Instructions Parameter DWORD-1
        SFDP_array(16#0150#) := 16#7B#;
        SFDP_array(16#0151#) := 16#92#;
        SFDP_array(16#0152#) := 16#0F#;
        SFDP_array(16#0153#) := 16#FE#;
        -- JEDEC 4-Byte Address Instructions Parameter DWORD-2
        SFDP_array(16#0154#) := 16#21#;
        SFDP_array(16#0155#) := 16#FF#;
        SFDP_array(16#0156#) := 16#FF#;
        SFDP_array(16#0157#) := 16#DC#;
        
        ----------------------------------------------------------------------/
        -- Status, Control and Configuration Register Map Offsets for
        -- Multi-Chip SPI Memory Devices
        ----------------------------------------------------------------------/
        -- Status, Control and Configuration Register Map DWORD-1
        SFDP_array(16#0158#) := 16#00#;
        SFDP_array(16#0159#) := 16#00#;
        SFDP_array(16#015A#) := 16#80#;
        SFDP_array(16#015B#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-2
        SFDP_array(16#015C#) := 16#00#;
        SFDP_array(16#015D#) := 16#00#;
        SFDP_array(16#015E#) := 16#00#;
        SFDP_array(16#015F#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-3
        SFDP_array(16#0160#) := 16#C0#;
        SFDP_array(16#0161#) := 16#FF#;
        SFDP_array(16#0162#) := 16#C3#;
        SFDP_array(16#0163#) := 16#EB#;
        -- Status, Control and Configuration Register Map DWORD-4
        SFDP_array(16#0164#) := 16#C8#;
        SFDP_array(16#0165#) := 16#FF#;
        SFDP_array(16#0166#) := 16#E3#;
        SFDP_array(16#0167#) := 16#EB#;
        -- Status, Control and Configuration Register Map DWORD-5
        SFDP_array(16#0168#) := 16#00#;
        SFDP_array(16#0169#) := 16#65#;
        SFDP_array(16#016A#) := 16#00#;
        SFDP_array(16#016B#) := 16#90#;
        -- Status, Control and Configuration Register Map DWORD-6
        SFDP_array(16#016C#) := 16#06#;
        SFDP_array(16#016D#) := 16#05#;
        SFDP_array(16#016E#) := 16#00#;
        SFDP_array(16#016F#) := 16#A1#;
        -- Status, Control and Configuration Register Map DWORD-7
        SFDP_array(16#0170#) := 16#00#;
        SFDP_array(16#0171#) := 16#65#;
        SFDP_array(16#0172#) := 16#00#;
        SFDP_array(16#0173#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-8
        SFDP_array(16#0174#) := 16#00#;
        SFDP_array(16#0175#) := 16#65#;
        SFDP_array(16#0176#) := 16#00#;
        SFDP_array(16#0177#) := 16#95#;
        -- Status, Control and Configuration Register Map DWORD-9
        SFDP_array(16#0178#) := 16#71#;
        SFDP_array(16#0179#) := 16#65#;
        SFDP_array(16#017A#) := 16#03#;
        SFDP_array(16#017B#) := 16#D0#;
        -- Status, Control and Configuration Register Map DWORD-10
        SFDP_array(16#017C#) := 16#71#;
        SFDP_array(16#017D#) := 16#65#;
        SFDP_array(16#017E#) := 16#03#;
        SFDP_array(16#017F#) := 16#D0#;
        -- Status, Control and Configuration Register Map DWORD-11
        SFDP_array(16#0180#) := 16#00#;
        SFDP_array(16#0181#) := 16#00#;
        SFDP_array(16#0182#) := 16#00#;
        SFDP_array(16#0183#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-12
        SFDP_array(16#0184#) := 16#B0#;
        SFDP_array(16#0185#) := 16#2E#;
        SFDP_array(16#0186#) := 16#00#;
        SFDP_array(16#0187#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-13
        SFDP_array(16#0188#) := 16#88#;
        SFDP_array(16#0189#) := 16#A4#;
        SFDP_array(16#018A#) := 16#89#;
        SFDP_array(16#018B#) := 16#AA#;
        -- Status, Control and Configuration Register Map DWORD-14
        SFDP_array(16#018C#) := 16#71#;
        SFDP_array(16#018D#) := 16#65#;
        SFDP_array(16#018E#) := 16#03#;
        SFDP_array(16#018F#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-15
        SFDP_array(16#0190#) := 16#71#;
        SFDP_array(16#0191#) := 16#65#;
        SFDP_array(16#0192#) := 16#03#;
        SFDP_array(16#0193#) := 16#96#;
        -- Status, Control and Configuration Register Map DWORD-16
        SFDP_array(16#0194#) := 16#00#;
        SFDP_array(16#0195#) := 16#00#;
        SFDP_array(16#0196#) := 16#00#;
        SFDP_array(16#0197#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-17
        SFDP_array(16#0198#) := 16#00#;
        SFDP_array(16#0199#) := 16#00#;
        SFDP_array(16#019A#) := 16#00#;
        SFDP_array(16#019B#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-18
        SFDP_array(16#019C#) := 16#00#;
        SFDP_array(16#019D#) := 16#00#;
        SFDP_array(16#019E#) := 16#00#;
        SFDP_array(16#019F#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-19
        SFDP_array(16#01A0#) := 16#00#;
        SFDP_array(16#01A1#) := 16#00#;
        SFDP_array(16#01A2#) := 16#00#;
        SFDP_array(16#01A3#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-20
        SFDP_array(16#01A4#) := 16#00#;
        SFDP_array(16#01A5#) := 16#00#;
        SFDP_array(16#01A6#) := 16#00#;
        SFDP_array(16#01A7#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-21
        SFDP_array(16#01A8#) := 16#00#;
        SFDP_array(16#01A9#) := 16#00#;
        SFDP_array(16#01AA#) := 16#00#;
        SFDP_array(16#01AB#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-22
        SFDP_array(16#01AC#) := 16#00#;
        SFDP_array(16#01AD#) := 16#00#;
        SFDP_array(16#01AE#) := 16#00#;
        SFDP_array(16#01AF#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-23
        SFDP_array(16#01B0#) := 16#00#;
        SFDP_array(16#01B1#) := 16#00#;
        SFDP_array(16#01B2#) := 16#00#;
        SFDP_array(16#01B3#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-24
        SFDP_array(16#01B4#) := 16#00#;
        SFDP_array(16#01B5#) := 16#00#;
        SFDP_array(16#01B6#) := 16#00#;
        SFDP_array(16#01B7#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-25
        SFDP_array(16#01B8#) := 16#00#;
        SFDP_array(16#01B9#) := 16#00#;
        SFDP_array(16#01BA#) := 16#00#;
        SFDP_array(16#01BB#) := 16#00#;
        -- Status, Control and Configuration Register Map DWORD-26
        SFDP_array(16#01BC#) := 16#71#;
        SFDP_array(16#01BD#) := 16#65#;
        SFDP_array(16#01BE#) := 16#05#;
        SFDP_array(16#01BF#) := 16#D5#;
        -- Status, Control and Configuration Register Map DWORD-27
        SFDP_array(16#01C0#) := 16#71#;
        SFDP_array(16#01C1#) := 16#65#;
        SFDP_array(16#01C2#) := 16#05#;
        SFDP_array(16#01C3#) := 16#D5#;
        -- Status, Control and Configuration Register Map DWORD-28
        SFDP_array(16#01C4#) := 16#00#;
        SFDP_array(16#01C5#) := 16#00#;
        SFDP_array(16#01C6#) := 16#A0#;
        SFDP_array(16#01C7#) := 16#15#;
        
        
        -- Sector Map DWORD-1
        SFDP_array(16#01C8#) := 16#FC#;
        SFDP_array(16#01C9#) := 16#65#;
        SFDP_array(16#01CA#) := 16#FF#;
        SFDP_array(16#01CB#) := 16#08#;
        -- Sector Map DWORD-2
        SFDP_array(16#01CC#) := 16#04#;
        SFDP_array(16#01CD#) := 16#00#;
        SFDP_array(16#01CE#) := 16#80#;
        SFDP_array(16#01CF#) := 16#00#;
        -- Sector Map DWORD-3
        SFDP_array(16#01D0#) := 16#FC#;
        SFDP_array(16#01D1#) := 16#65#;
        SFDP_array(16#01D2#) := 16#FF#;
        SFDP_array(16#01D3#) := 16#40#;
        -- Sector Map DWORD-4
        SFDP_array(16#01D4#) := 16#02#;
        SFDP_array(16#01D5#) := 16#00#;
        SFDP_array(16#01D6#) := 16#80#;
        SFDP_array(16#01D7#) := 16#00#;
        -- Sector Map DWORD-5
        SFDP_array(16#01D8#) := 16#FD#;
        SFDP_array(16#01D9#) := 16#65#;
        SFDP_array(16#01DA#) := 16#FF#;
        SFDP_array(16#01DB#) := 16#04#;
        -- Sector Map DWORD-6
        SFDP_array(16#01DC#) := 16#02#;
        SFDP_array(16#01DD#) := 16#00#;
        SFDP_array(16#01DE#) := 16#80#;
        SFDP_array(16#01DF#) := 16#00#;
        -- Sector Map DWORD-7
        SFDP_array(16#01E0#) := 16#FE#;
        SFDP_array(16#01E1#) := 16#00#;
        SFDP_array(16#01E2#) := 16#02#;
        SFDP_array(16#01E3#) := 16#FF#;
        -- Sector Map DWORD-8
        SFDP_array(16#01E4#) := 16#F1#;
        SFDP_array(16#01E5#) := 16#FF#;
        SFDP_array(16#01E6#) := 16#01#;
        SFDP_array(16#01E7#) := 16#00#;
        -- Sector Map DWORD-9
        SFDP_array(16#01E8#) := 16#F8#;
        SFDP_array(16#01E9#) := 16#FF#;
        SFDP_array(16#01EA#) := 16#01#;
        SFDP_array(16#01EB#) := 16#00#;
        -- Sector Map DWORD-10
        SFDP_array(16#01EC#) := 16#F8#;
        SFDP_array(16#01ED#) := 16#FF#;
        SFDP_array(16#01EE#) := 16#FB#;
        SFDP_array(16#01EF#) := 16#07#;
        -- Sector Map DWORD-11
        SFDP_array(16#01F0#) := 16#FE#;
        SFDP_array(16#01F1#) := 16#03#;
        SFDP_array(16#01F2#) := 16#02#;
        SFDP_array(16#01F3#) := 16#FF#;
        -- Sector Map DWORD-12
        SFDP_array(16#01F4#) := 16#F8#;
        SFDP_array(16#01F5#) := 16#FF#;
        SFDP_array(16#01F6#) := 16#FB#;
        SFDP_array(16#01F7#) := 16#07#;
        -- Sector Map DWORD-13
        SFDP_array(16#01F8#) := 16#F8#;
        SFDP_array(16#01F9#) := 16#FF#;
        SFDP_array(16#01FA#) := 16#01#;
        SFDP_array(16#01FB#) := 16#00#;
        -- Sector Map DWORD-14
        SFDP_array(16#01FC#) := 16#F1#;
        SFDP_array(16#01FD#) := 16#FF#;
        SFDP_array(16#01FE#) := 16#01#;
        SFDP_array(16#01FF#) := 16#00#;
        -- Sector Map DWORD-15
        SFDP_array(16#0200#) := 16#FE#;
        SFDP_array(16#0201#) := 16#01#;
        SFDP_array(16#0202#) := 16#04#;
        SFDP_array(16#0203#) := 16#FF#;
        -- Sector Map DWORD-16
        SFDP_array(16#0204#) := 16#F1#;
        SFDP_array(16#0205#) := 16#FF#;
        SFDP_array(16#0206#) := 16#00#;
        SFDP_array(16#0207#) := 16#00#;
        -- Sector Map DWORD-17
        SFDP_array(16#0208#) := 16#F8#;
        SFDP_array(16#0209#) := 16#FF#;
        SFDP_array(16#020A#) := 16#02#;
        SFDP_array(16#020B#) := 16#00#;
        -- Sector Map DWORD-18
        SFDP_array(16#020C#) := 16#F8#;
        SFDP_array(16#020D#) := 16#FF#;
        SFDP_array(16#020E#) := 16#F7#;
        SFDP_array(16#020F#) := 16#07#;
        -- Sector Map DWORD-19
        SFDP_array(16#0210#) := 16#F8#;
        SFDP_array(16#0211#) := 16#FF#;
        SFDP_array(16#0212#) := 16#02#;
        SFDP_array(16#0213#) := 16#00#;
        -- Sector Map DWORD-20
        SFDP_array(16#0214#) := 16#F1#;
        SFDP_array(16#0215#) := 16#FF#;
        SFDP_array(16#0216#) := 16#00#;
        SFDP_array(16#0217#) := 16#00#;
        -- Sector Map DWORD-21
        SFDP_array(16#0218#) := 16#FF#;
        SFDP_array(16#0219#) := 16#04#;
        SFDP_array(16#021A#) := 16#00#;
        SFDP_array(16#021B#) := 16#FF#;
        -- Sector Map DWORD-22
        SFDP_array(16#021C#) := 16#F8#;
        SFDP_array(16#021D#) := 16#FF#;
        SFDP_array(16#021E#) := 16#FF#;
        SFDP_array(16#021F#) := 16#07#;

        WAIT;
    END PROCESS SFDPPreload;

    ---------------------------------------------------------------------------
    ---- File Read Section - Preload Control
    ---------------------------------------------------------------------------

    default:    PROCESS

    -- text file input variables
        FILE mem_f            : text  is  mem_file;
        FILE otp_f            : text  is  otp_file;
        VARIABLE ind          : NATURAL RANGE 0 TO AddrRANGE := 0;
        VARIABLE otp_ind      : NATURAL RANGE 16#000# TO 16#3FF# := 16#000#;
        VARIABLE buf          : line;
        VARIABLE S_ind        : NATURAL RANGE 0 TO SecNumHyb:= 0;
        VARIABLE index        : NATURAL RANGE 0 TO SecSize256:=0;

BEGIN
    --Preload Control
    ---------------------------------------------------------------------------
    -- File Read Section
    ---------------------------------------------------------------------------
            -- memory preload
        IF (mem_file(1 to 4) /= "none") THEN
            ind := 0;
            configure_memory(16#FF#);
            initialize;
            WHILE (not ENDFILE (mem_f)) LOOP
                READLINE (mem_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    ind := h(buf(2 to 8)); --address







                ELSE
                    IF ind <= AddrRANGE THEN
                        mem_data := h(buf(1 to 2));
                        IF ind=0 THEN
                            S_ind := 0;
                            index := 0;
                        ELSIF ind < SecSize256+1  THEN
                            S_ind := 0;
                            index := ind;
                        ELSE
                            S_ind := NATURAL(ind / (SecSize256 +1));
                            index := ind - S_ind*(SecSize256+1);
                        END IF;
                        WRITE_DATA(S_ind,index,mem_data);
                        IF ind < AddrRANGE THEN
                            ind := ind + 1;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;

         -- memory preload
        IF (otp_file(1 to 4) /= "none" AND UserPreload = 1) THEN
            otp_ind := 16#000#;
            Otp := (OTHERS => MaxData);
            WHILE (not ENDFILE (otp_f)) LOOP
                READLINE (otp_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF otp_ind > 16#3FF# OR otp_ind < 16#000# THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "OTP address range"
                            SEVERITY warning;
                    ELSE
                        otp_ind := h(buf(2 to 4)); --address
                    END IF;
                ELSE
                    Otp(otp_ind) := h(buf(1 to 2));
                    otp_ind := otp_ind + 1;
                END IF;
            END LOOP;
        END IF;

        LOCK_BYTE1 := to_slv(Otp(16#10#),8);
        LOCK_BYTE2 := to_slv(Otp(16#11#),8);
        LOCK_BYTE3 := to_slv(Otp(16#12#),8);
        LOCK_BYTE4 := to_slv(Otp(16#13#),8);

    WAIT;

END PROCESS default;

END vhdl_behavioral_dynamic_memory_allocation;
