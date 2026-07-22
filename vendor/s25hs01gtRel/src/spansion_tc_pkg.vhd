-------------------------------------------------------------------------------
--  File name : spansion_tc_pkg.vhd
-------------------------------------------------------------------------------
--  Copyright (C) 2018 Cypress Semiconductor Corporation
--
--  MODIFICATION HISTORY :
--
--  version: |    author:      |  mod date: | changes made:
--    V1.0        B.Barac       18 June 28      Inital Release
--    V1.1        B.Barac       18 July 23      Updated according rev *I 
--                                             (aded QPI legacy reset, 
--                                              changed some register default value
--                                              and sfdp)
--    V1.2        M.Krneta      19 Feb 14       Updated according to the rev *L
--                                              (SFDP, timings, transaction table)
--    V1.3        M.Krneta      19 Mar 11       Bug39 fix MSB addresses
--    V1.4        M.Krneta      19 Dec 13       Bit-walking bug fixed
--    V1.5        M.Krneta      20 Jun 15       bug50 fixed, RDBSY and WRPGEN bits
--                                              stay '1' if bit walking error occurs
--    V1.6        S.Stevanovic  03 Oct 20       Update to revision *X
--                                              (SFDP only),
--                                              Removing dependency between
--                                              QUADIT and QPI
--    V1.7        N. Naim		11 Apr 22		Check DQ3 reset pin, Register_latency
--												for Volatile read
-------------------------------------------------------------------------------
--  PART DESCRIPTION:
--
--  Description:
--              Generic test environment for verification of flash memory
--              VITAL models.
--              For models:
--                  S25HS01GT
--
-------------------------------------------------------------------------------
--  Known Bugs:
--
-------------------------------------------------------------------------------
LIBRARY IEEE;
                USE IEEE.std_logic_1164.ALL;
                USE STD.textio.ALL;

LIBRARY FMF;
                USE FMF.gen_utils.all;
                USE FMF.conversions.all;
-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
PACKAGE spansion_tc_pkg IS
    ---------------------------------------------------------------------------
    --Values specified in this section determine wait periods of programming,
    --erase and internal device operation
    --Min, typ and max SDF parameters should all be supported for all timing
    --models.When FTM or SDF values change,and are not supported
    --these values may need to be updated.
    ---------------------------------------------------------------------------
    SHARED VARIABLE   tW       : time;  -- WRR cycle time
    SHARED VARIABLE   tPP256   : time;  -- page program time
    SHARED VARIABLE   tPP512   : time;  -- page program time
    SHARED VARIABLE   tSE4     : time;  -- sector erase time
    SHARED VARIABLE   tSE256   : time;  -- sector erase time
    SHARED VARIABLE   tSEERC   : time;  -- sector erase count register time
    SHARED VARIABLE   tBE      : time;  -- bulk (chip) erase time
    SHARED VARIABLE   tEES     : time;  -- Evaluate Erase Status Time
    SHARED VARIABLE   tEPS     : time;  -- program/erase suspend time
    SHARED VARIABLE   tRS      : time;  -- Resume to next Suspend Time
    SHARED VARIABLE tDIC_SETUP : time;  -- DIC Calc time
    SHARED VARIABLE   tDICSL   : time;  -- DIC suspend latency
    SHARED VARIABLE   tPU      : time;  -- VCC (min) to CS# Low time
    SHARED VARIABLE   tRH     : time;  -- RESET# low to next instruction time
    SHARED VARIABLE   tRP      : time;  -- RESET# Pulse Width
    SHARED VARIABLE   tPACC    : time;  -- Ready to accept PASSU command
    SHARED VARIABLE   tENTDPD     : time;  -- Time to Enter DPD mode
    SHARED VARIABLE   tEXTDPD     : time;  -- Time to Exit DPD mode
    SHARED VARIABLE   tCSDPD     : time;  -- CS# High to Power Down Mode  tCSPOR
    SHARED VARIABLE   tCSPOR     : time;  -- Chip Select to high to enter DPD during POR or Reset

    ---------------------------------------------------------------------------
    --TC type
    ---------------------------------------------------------------------------
    TYPE TC_type IS RECORD
                        SERIES   : NATURAL RANGE 1 TO 45;
                        TESTCASE : NATURAL RANGE 1 TO 15;
                    END RECORD;
    ---------------------------------------------------------------------------
    -- commands to the device
    ---------------------------------------------------------------------------
    TYPE cmd_type IS (  done,
                        idle,
                        w_enable,
                        w_wrenv,
                        w_disable,
                        reset_en,
                        rst,
                        reset_cmd,
                        bam4,
                        bax4,
                        ees,
                        set_bl,
                        h_reset,
						h_io3_reset,
                        w_sr,
                        wrar,
                        read_SR1,
                        read_SR2,
                        read_CR1,
                        clr_sr,
                        w_scr,
                        rd_dlp,
                        rd,
                        rd_4,
                        fast_rd,
                        fast_rd4,
                        dual_high_rd,
                        dual_high_rd_4,
                        quad_rd,
                        quad_rd_4,
                        quad_high_rd,
                        quad_high_rd_4,
                        quad_high_ddr_rd,
                        quad_high_ddr_rd_4,
                        read_JID,
                        read_JQID,
                        read_RUID,
                        read_SFDP,
                        csneg_zero,
                        dp_down,
                        sector_erase,
                        sector_erase_4,
                        p4_erase,
                        p4_erase_4,
                        bulk_erase_60,
                        bulk_erase_C7,
                        ers_susp_b0,
                        ers_susp_75,
                        ers_susp_85,
                        ers_resume_7a,
                        ers_resume_8a,
                        pg_prog,
                        pg_prog4,
                        prg_susp_b0,
                        prg_susp_75,
                        prg_susp_85,
                        prg_resume_7a,
                        prg_resume_8a,
                        otp_prog,
                        otp_read,
                        w_nvldr,
                        w_wvdlr,
                        w_autoboot,
                        w_asp,
                        pass_reg_rd,
                        w_password,
                        psw_unlock,
                        ppbl_reg_rd,
                        w_ppbl_reg,
                        ppbacc_rd,
                        ppbacc_rd4,
                        w_ppb,
                        w_ppb4,
                        ppb_ers,
                        dybacc_rd,
                        dybacc_rd4,
                        ecc_read,
                        ecc_read4,
                        rdar_read,
                        w_dic,
                        w_dyb,
                        w_dyb4,
                        wt,
                        inv_write,
                        seerc_rd,
                        assert_cs,
                        jedec_reset
                     );

    ---------------------------------------------------------------------------
    -- condition to be verified
    ---------------------------------------------------------------------------
    -- list of data/ status to be veriied by checker
    TYPE status_type IS ( none,
                          read,
                          read_4,
                          read_fast,
                          read_fast_4,
                          read_fast_4_IO,
                          read_dual,
                          read_dual_4,
                          rd_quad,
                          rd_quad_4,
                          read_dual_hi,
                          read_dual_hi4,
                          rd_cont_dualIO,
                          rd_cont_dualIO4,
                          read_quad_hi,
                          read_quad_hi4,
                          rd_cont_quadIO,
                          rd_cont_quadIO4,
                          read_ddr_fast,
                          read_ddr_fast4,
                          rd_cont_fddr,
                          rd_cont_fddr4,
                          read_ddr_dual_hi,
                          read_ddr_dual_hi4,
                          rd_cont_dddr,
                          rd_cont_dddr4,
                          read_ddr_quad_hi,
                          read_ddr_quad_hi4,
                          rd_cont_qddr,
                          rd_cont_qddr4,
                          rd_HiZ,
                          rd_U,
                          read_otp,
                          rd_JID,
                          rd_JQID,
                          rd_SFDP,
                          rd_SR1,
                          rd_SR2,
                          rd_CR1,
                          rd_CR2,
                          rd_CR3,
                          rd_CR4,
                          read_autoboot,
                          read_bank,
                          read_rdar,
                          read_dlp,
                          read_asp,
                          read_pass_reg,
                          read_ppbl,
                          read_ppbar,
                          read_ppbar_4,
                          read_ecc,
                          read_ecc_4,
                          read_dybar,
                          read_dybar_4,
                          rd_ppblock_0,
                          rd_ppblock_1,
                          rd_wip_0,
                          rd_wip_1,
                          rd_wel_0,
                          rd_wel_1,
                          erase_succ,
                          erase_nosucc,
                          pgm_succ,
                          pgm_nosucc,
                          rd_ps_0,
                          rd_ps_1,
                          rd_es_0,
                          rd_es_1,
                          chk_sts_1,
                          chk_sts_0,
                          err
                        );
    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    TYPE Aux_type IS (  valid,
                        violate,
                        clock_num,
                        break,
                        PowerUp
                     );

    TYPE DEVICE_MODE IS ( DEFAULT_PROTECTION,
                          PERSISTENT_PROTECTION,
                          PASSWORD_PROTECTION,
                          TEST_SEERC_READ,
                          TEST_JEDEC_RESET,
                          AUTOBOOT_TEST);

    TYPE cmd_rec IS
        RECORD
            cmd      :   cmd_type;
            status   :   status_type;
            byte_num :   NATURAL RANGE 0 TO 16#2000#;
            data4    :   NATURAL ;
            data3    :   NATURAL ;
            data2    :   NATURAL ;
            data1    :   NATURAL ;
            sect     :   INTEGER RANGE 0 TO 543;
            addr     :   INTEGER RANGE 0 TO 16#7FFFFFF#;
            aux      :   Aux_type;
            wtime    :   time;
        END RECORD;

    --number of testcases per testseries
    TYPE tc_list IS  ARRAY (1 TO 42) OF NATURAL;
    CONSTANT tc : tc_list :=
    --0                  1                    2                   3                4
    --1-2-3-4-5-6-7-8 -9-0-1-2-3-4-5-6-7-8-9-0-1-2-3-4-5-6-7-8-9-0-1-2-3-4-5-6-7-8-9-0-1-2
--      (1,1,2,2,4,1,5,10,1,3,1,1,1,2,2,3,4,2,1,2,3,1,2,3,1,1,1,3,2,4,1,3,2);
     (1,1,3,2,4,1,5,10,1,3,1,1,1,3,3,3,10,2,1,2,3,1,2,3,1,1,1,3,2,4,1,1,2,3,2,1,1,1,2,3,3,3);

    --TC command sequence
    TYPE cmd_seq_type IS ARRAY(0 TO 250) OF cmd_rec;

    ---------------------------------------------------------------------------
    --PUBLIC
    --PROCEDURE to generate command sequence
    ---------------------------------------------------------------------------
    PROCEDURE   Generate_TC
         (  Model       : IN  STRING  ;
            Series      : IN  NATURAL RANGE 1 TO 45;
            TestCase    : IN  NATURAL RANGE 1 TO 15;
            Sec_Arch    : IN  BOOLEAN  ;
            command_seq : OUT cmd_seq_type
         );
    ---------------------------------------------------------------------------
    --PUBLIC
    --PROCEDURE to set DUT dependant parameters
    ---------------------------------------------------------------------------
    PROCEDURE   TestInit (
            Model        : IN  STRING;
            LongTimming  : IN  boolean);
    ---------------------------------------------------------------------------
    --PUBLIC
    -- CHECKER PROCEDURES
    ---------------------------------------------------------------------------
    PROCEDURE   Check_read (
        DQ       :  IN std_logic_vector(7 downto 0);
        DQ_reg0  :  IN std_logic_vector(7 downto 0);
        DQ_reg1  :  IN std_logic_vector(7 downto 0);
        DQ_reg2  :  IN std_logic_vector(7 downto 0);
        DQ_reg3  :  IN std_logic_vector(7 downto 0);
        D_mem    :  IN NATURAL;
        DLP_reg  :  IN NATURAL;
        D_dlp_act:  IN std_logic_vector(1 downto 0);
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_Z (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_U (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_X (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_otp_read (
        DQ   :  IN std_logic_vector(7 downto 0);
        otp_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_JID (
        DQ               :  IN std_logic_vector(7 downto 0);
        VDATA            :  IN NATURAL;
        byte_no          :  IN NATURAL;
        SIGNAL check_err :  OUT std_logic);

    PROCEDURE   Check_read_SFDP (
        DQ               :  IN std_logic_vector(7 downto 0);
        VDATA            :  IN NATURAL;
        SIGNAL check_err :  OUT std_logic);

    PROCEDURE   Check_read_sr1 (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_sr2 (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_rdar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_config (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_dlp (
        DQ     :  IN std_logic_vector(7 downto 0);
        DLP_reg:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_autoboot (
        DQ   :  IN std_logic_vector(31 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_bank (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_asp (
        DQ   :  IN std_logic_vector(15 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_pass_reg (
        DQ   :  IN std_logic_vector(63 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_ppbl (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_ppbar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_ecc (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_read_dybar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_PPBLOCK_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_WIP_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_WEL_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_eers_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE   Check_epgm_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE Check_PS_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

    PROCEDURE Check_ES_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic);

END PACKAGE  spansion_tc_pkg;

PACKAGE BODY spansion_tc_pkg IS

    PROCEDURE   TestInit ( Model       : IN  STRING;
                           LongTimming  : IN  BOOLEAN  )
    IS
    BEGIN
        IF LongTimming THEN
            -- WRR cycle time
            tW     := 357.5 ms;
            -- Page Program Operation
            tPP256 := 1700 us;
            -- Page Program Operation
            tPP512 := 1700 us;
            -- Sector Erase Operation
            tSE4   := 335 ms;
            -- Sector Erase Operation
            tSE256 := 2677 ms;
            -- Sector Erase Count Register max time
            -- max, typ and min are comming from SDF file so always use here
            -- max time as it is not known which sdf time will be used for sim.
            tSEERC := 60 us;
            -- Bulk Erase Operation
            tBE    := 1381 sec;
            -- Evaluate Erase Status Time
            tEES   := 50 us;
            -- Suspend Latency
            tEPS   := 60 us;
            -- Resume to next Suspend Time
            tRS    := 100 us;
            -- DIC Setup time
            tDIC_SETUP  := 17 us;
            -- DIC Suspend Latency
            tDICSL  := 60 us;
            -- VDD (min) to CS# Low
            tPU    := 450 us;
            -- RESET# low to next instruction time
            tRH   := 450 us;
            -- RESET# Pulse Width
            tRP    := 200 ns;
            -- Ready to accept PASSU command
            tPACC  := 100 us;
            -- Time to Enter DPD mode
            tENTDPD := 3 us;
            -- CS# High to Power Down Mode -- tDPD
            tCSDPD := 20 ns;
            -- Time to Exit DPD mode
            tEXTDPD := 350 us;
            -- Chip Select to high to enter DPD during POR or Reset
            tCSPOR := 150 us;
        ELSE
            -- WRR cycle time
            tW     := 357.5 us;
            -- Page Program Operation
            tPP256 := 170 us;
            -- Page Program Operation
            tPP512 := 170 us;
            -- Sector Erase Operation
            tSE4   := 3350 us;
            -- Sector Erase Operation
            tSE256 := 26.77 ms;
            -- Sector Erase Count Register max time
            -- max, typ and min are comming from SDF file so always use here
            -- max time as it is not known which sdf time will be used for sim.
            tSEERC := 6 us;
            -- Bulk Erase Operation
            tBE    := 1381 ms;
            -- Evaluate Erase Status Time
            tEES   := 5 us;
            -- Suspend Latency
            tEPS   := 6 us;
            -- Resume to next Suspend Time
            tRS    := 10 us;
            -- DIC Setup time
            tDIC_SETUP  := 17 us;
            -- DIC Suspend Latency
            tDICSL  := 60 us;
            -- VDD (min) to CS# Low
            tPU    := 450 us;
            -- RESET# low to next instruction time
            tRH   := 450 us;
            -- RESET# Pulse Width
            tRP    := 200 ns;
            -- Ready to accept PASSU command
            tPACC  := 100 us;
            -- Time to Enter DPD mode
            tENTDPD := 3 us;
            -- CS# High to Power Down Mode -- tDPD
            tCSDPD := 20 ns;
            -- Time to Exit DPD mode
            tEXTDPD := 350 us;
            -- Chip Select to high to enter DPD during POR or Reset
            tCSPOR := 150 us;
        END IF;

    END PROCEDURE TestInit;
    ---------------------------------------------------------------------------
    --Public PROCEDURE to generate command sequence
    ---------------------------------------------------------------------------
    PROCEDURE   Generate_TC
         (  Model       : IN  STRING;
            Series      : IN  NATURAL RANGE 1 TO 45;
            TestCase    : IN  NATURAL RANGE 1 TO 15;
            Sec_Arch    : IN  BOOLEAN  ;
            command_seq : OUT cmd_seq_type
         )
    IS

    BEGIN

        FOR i IN 1 TO 200 LOOP
            --cmd,sts,byte_num,data4,data3,data2,data1,sect,addr,aux_t,time
            command_seq(i) :=(done,none,0,0,0,0,0,0,0,valid,0 ns);
        END LOOP;

REPORT LF&
            "------------------------------------------------------"&LF&
            "------------------------------------------------------"&LF&
            "TestSeries : "& to_int_str(Series )&"   "&
            "TC         : "& to_int_str(TestCase)&LF&
            "------------------------------------------------------" ;
        CASE Series IS
            WHEN 1  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "POWERUP negative test";
                    -- warning is generated if device is selected on PowerUp
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,200 ns);
                    command_seq(3) :=(rd     ,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPU);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,none,3,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 2  =>
                REPORT "POWERUP positive test";
                --cmd,sts,byte_num,data4,data3,data2,data1,sect,addr,aux_t,time
                command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(2) :=(rd     ,read  ,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(4) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(5) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(6) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(7) :=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(8):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(9) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                -- Set QA bit to '1'
                command_seq(7) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(9) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                command_seq(10) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(11):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                command_seq(12):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(13):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(14):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                command_seq(15) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);    
                command_seq(16) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                -- Set QA bit to '0'
                command_seq(18) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(19) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(20):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(22):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(24):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                
                command_seq(26) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(27) :=(rd     ,read  ,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(28) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(29) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(30) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(31) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(32) :=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(34) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

            WHEN 3  =>  --write enable/write disable positive tests
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "WREN positive test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR1 ,rd_wel_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "WRDI positive test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR1 ,rd_wel_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN 3  =>
                    REPORT "01h command positive test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(4) :=(w_sr  ,none   ,1,0,0,0,16#00#,0,0,valid,0 ns);
--                     
--                     command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(8) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
--                     command_seq(9) :=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(10) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 4  =>  --Initial configuration test (TBPARM) for TopBoot Sector Architecture
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "TBPARM bit positive test";
                    IF Sec_Arch = FALSE THEN
                        --The desired state of TBPARM must be selected during the initial
                        --configuration of the device during system manufacture;
                        --before the first program or erase operation on the main Flash array.
                        --TBPARM must not be programmed after programming or erasing is done in
                        --the main Flash array.
                        command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(4) :=(w_scr  ,none     ,2,0,0,0,16#04#,0,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                        command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(10):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    WHEN 2  =>
                    REPORT "TBPARM bit negative test";
                    IF Sec_Arch = FALSE THEN
                        --If TBPARM is programmed to 1, an attempt to change it back
                        --to zero will be ignored and no error is set.
                        command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(4) :=(w_scr  ,err      ,2,0,0,0,16#00#,0,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that operation is ignored
                        --(Warning is generated)
                        command_seq(6) :=(read_SR1 ,rd_wip_0 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that P_ERR bit is not set
                        command_seq(8) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that TBPARM did not change its value
                        command_seq(10):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(14):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 5  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "Block protection, positive test";
                    -- TBPROT = '0'
                    ------------------------------------------------------------
                    -- Hybrid Architecture
                    ------------------------------------------------------------
                    command_seq(0) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(w_sr  ,none      ,1,0,0,0,16#04#,0,0,valid,0 ns);
                    command_seq(4) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(8) :=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 504 to 543 are locked
                        command_seq(10):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(pg_prog4,none    ,5,0,0,0,16#99#,504,20,valid,0 ns);
                        command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(17):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(25):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(26):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(28):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(30):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 520 to 543 are locked
                        command_seq(10):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(pg_prog4,none    ,5,0,0,0,16#99#,520,20,valid,0 ns);
                        command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(17):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(25):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(26):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(28):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(30):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(32):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(w_sr  ,none      ,1,0,0,0,16#08#,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(39):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 496 to 543 are locked
                        command_seq(41):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(42):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(43):=(sector_erase_4,none    ,5,0,0,0,16#99#,496,10,valid,0 ns);
                        command_seq(44):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When E_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(45):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(46):=(read_SR1 ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(48):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(49):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(50):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(54):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(57):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(59):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(61):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(62):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 512 to 543 are locked
                        command_seq(41):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(42):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(43):=(sector_erase_4,none    ,5,0,0,0,16#99#,512,10,valid,0 ns);
                        command_seq(44):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(45):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(46):=(read_SR1 ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(48):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(49):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(50):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(54):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(57):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(59):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(61):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(62):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(63):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(w_sr  ,none      ,1,0,0,0,16#0C#,0,0,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(69):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(70):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 480 to 543 are locked
                        command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(74):=(pg_prog4,none    ,5,0,0,0,16#99#,480,20,valid,0 ns);
                        command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(77):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(78):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(79):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(80):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(81):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(82):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(83):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(84):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(85):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(86):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(87):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(88):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(89):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(90):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(91):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(92):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 496 to 543 are locked
                        command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(74):=(pg_prog4,none    ,5,0,0,0,16#99#,496,20,valid,0 ns);
                        command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(77):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(78):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(79):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(80):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(81):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(82):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(83):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(84):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(85):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(86):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(87):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(88):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(89):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(90):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(91):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(92):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(94):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(w_sr  ,none      ,1,0,0,0,16#10#,0,0,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(101):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 448 to 543 are locked
                        command_seq(103):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(104):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(105):=(pg_prog4,none    ,5,0,0,0,16#99#,448,20,valid,0 ns);
                        command_seq(106):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(107):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(108):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(109):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(110):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(111):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(112):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(113):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(114):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(116):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(118):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(119):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(120):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(121):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(122):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(123):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(124):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 464 to 543 are locked
                        command_seq(103):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(104):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(105):=(pg_prog4,none    ,5,0,0,0,16#99#,464,20,valid,0 ns);
                        command_seq(106):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(107):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(108):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(109):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(110):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(111):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(112):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(113):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(114):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(116):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(118):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(119):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(120):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(121):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(122):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(123):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(124):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(125):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(127):=(w_sr  ,none      ,1,0,0,0,16#14#,0,0,valid,0 ns);
                    command_seq(128):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(129):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(131):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(132):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(133):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 384 to 543 are locked
                        command_seq(134):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(135):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(136):=(pg_prog4,none    ,5,0,0,0,16#99#,384,20,valid,0 ns);
                        command_seq(137):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(138):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(139):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(140):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(141):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(142):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(143):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(144):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(145):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(147):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(149):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(150):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(151):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(152):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(153):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(154):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(155):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 400 to 543 are locked
                        command_seq(134):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(135):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(136):=(pg_prog4,none    ,5,0,0,0,16#99#,400,20,valid,0 ns);
                        command_seq(137):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(138):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(139):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(140):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(141):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(142):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(143):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(144):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(145):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(147):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(149):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(150):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(151):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(152):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(153):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(154):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(155):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(156):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(157):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(158):=(w_sr  ,none      ,1,0,0,0,16#18#,0,0,valid,0 ns);
                    command_seq(159):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(160):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(161):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(162):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(163):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(164):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 256 to 543 are locked
                        command_seq(165):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(166):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(167):=(pg_prog4,none    ,5,0,0,0,16#99#,256,20,valid,0 ns);
                        command_seq(168):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(169):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(170):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(171):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(172):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(173):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(174):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(175):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(176):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(178):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(180):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(181):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(182):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(183):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(184):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(185):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(186):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 272 to 543 are locked
                        command_seq(165):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(166):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(167):=(pg_prog4,none    ,5,0,0,0,16#99#,272,20,valid,0 ns);
                        command_seq(168):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(169):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(170):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(171):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(172):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(173):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(174):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(175):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(176):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(178):=(pg_prog4,none    ,5,0,0,0,16#99#,543,10,valid,0 ns);
                        command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(180):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(181):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(182):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(183):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(184):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(185):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(186):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(187):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(188):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(189):=(w_sr  ,none      ,1,0,0,0,16#1C#,0,0,valid,0 ns);
                    command_seq(190):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(191):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(192):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(193):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(194):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(195):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --All sectors are locked
                    command_seq(196):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(197):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(198):=(pg_prog4,none    ,5,0,0,0,16#99#,0,20,valid,0 ns);
                    command_seq(199):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(200):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(201):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(202):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(203):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(204):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(205):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(206):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(207):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(208):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(209):=(pg_prog4,none    ,5,0,0,0,16#99#,263,10,valid,0 ns);
                    command_seq(210):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(211):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(212):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(213):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(214):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(215):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(216):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(217):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(218):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Block protection, positive test";
                    -- TBPROT = '0'
                    ------------------------------------------------------------
                    -- Uniform Architecture
                    ------------------------------------------------------------
                    command_seq(0) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V is set to '1'
                    command_seq(3) :=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800004#,valid,0 ns);
                    command_seq(4) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(6) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(w_sr  ,none      ,1,0,0,0,16#04#,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(14):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Sectors from 504 to 511 are locked
                    command_seq(16):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(pg_prog4,none    ,5,0,0,0,16#99#,504,20,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(20):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(23):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(pg_prog4,none    ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(30):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(31):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(34):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(38):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(w_sr  ,none      ,1,0,0,0,16#08#,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(45):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 496 to 511 are locked
                    command_seq(47):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(pg_prog4,none    ,5,0,0,0,16#99#,496,20,valid,0 ns);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(51):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(54):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(pg_prog4,none    ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(62):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(65):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(69):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(w_sr  ,none      ,1,0,0,0,16#0C#,0,0,valid,0 ns);
                    command_seq(72):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(76):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 480 to 511 are locked
                    command_seq(78):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(pg_prog4,none    ,5,0,0,0,16#99#,480,20,valid,0 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(82):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(85):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(89):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91):=(pg_prog4,none    ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(92):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(93):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(94):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(96):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(100):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(w_sr  ,none      ,1,0,0,0,16#10#,0,0,valid,0 ns);
                    command_seq(103):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(105):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(107):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(108):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 448 to 511 are locked
                    command_seq(109):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(110):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(111):=(pg_prog4,none   ,5,0,0,0,16#99#,448,20,valid,0 ns);
                    command_seq(112):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(113):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(114):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(116):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(118):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(119):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(120):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(121):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(122):=(pg_prog4,none   ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(123):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(124):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(125):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(127):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(128):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(129):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(131):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(132):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(133):=(w_sr  ,none     ,1,0,0,0,16#14#,0,0,valid,0 ns);
                    command_seq(134):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(135):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(136):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(137):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(138):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(139):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 384 to 511 are locked
                    command_seq(140):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(141):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(142):=(pg_prog4,none   ,5,0,0,0,16#99#,384,20,valid,0 ns);
                    command_seq(143):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(144):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(145):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(147):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(149):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(150):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(151):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(152):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(153):=(pg_prog4,none   ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(154):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(155):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(156):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(157):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(158):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(159):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(160):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(161):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(162):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(163):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(164):=(w_sr  ,none     ,1,0,0,0,16#18#,0,0,valid,0 ns);
                    command_seq(165):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(166):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(167):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(168):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(169):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(170):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 256 to 511 are locked
                    command_seq(171):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(172):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(173):=(pg_prog4,none   ,5,0,0,0,16#99#,256,20,valid,0 ns);
                    command_seq(174):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(175):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(176):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(178):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(180):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(181):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(182):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(183):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(184):=(pg_prog4,none   ,5,0,0,0,16#99#,511,10,valid,0 ns);
                    command_seq(185):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(186):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(187):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(188):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(189):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(190):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(191):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(192):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(193):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(194):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(195):=(w_sr   ,none    ,1,0,0,0,16#1C#,0,0,valid,0 ns);
                    command_seq(196):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(197):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(198):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(199):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(200):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(201):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --All sectors are locked
                    command_seq(202):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(203):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(204):=(pg_prog4,none   ,5,0,0,0,16#99#,0,20,valid,0 ns);
                    command_seq(205):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(206):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(207):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(208):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(209):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(210):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(211):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(212):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(213):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(214):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(215):=(pg_prog4,none   ,5,0,0,0,16#99#,255,10,valid,0 ns);
                    command_seq(216):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(217):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(218):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(219):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(220):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(221):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(222):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(223):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(224):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "Block protection, positive test";
                    -- TBPROT = '1'
                    ------------------------------------------------------------
                    -- Uniform Architecture
                    ------------------------------------------------------------
                    command_seq(0) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Set TBPROT to '1'
                    IF Sec_Arch = FALSE THEN
                        command_seq(3):=(w_scr  ,none     ,2,0,0,0,16#24#,0,0,valid,0 ns);
                    ELSE
                        command_seq(3):=(w_scr  ,none     ,2,0,0,0,16#20#,0,0,valid,0 ns);
                    END IF;
                    command_seq(4) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(6) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(w_sr  ,none      ,1,0,0,0,16#04#,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(14):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Sectors from 0to 3 are locked
                    command_seq(16):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(20):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(23):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(pg_prog4,none    ,5,0,0,0,16#99#,3,10,valid,0 ns);
                    command_seq(30):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(31):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(34):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(38):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(w_sr  ,none      ,1,0,0,0,16#08#,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(45):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 0 to 7 are locked
                    command_seq(47):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(51):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(54):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(pg_prog4,none    ,5,0,0,0,16#99#,7,10,valid,0 ns);
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(62):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(65):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(69):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(w_sr  ,none      ,1,0,0,0,16#0C#,0,0,valid,0 ns);
                    command_seq(72):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(76):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 0 to 15 are locked
                    command_seq(78):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(82):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(85):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(89):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91):=(pg_prog4,none    ,5,0,0,0,16#99#,15,10,valid,0 ns);
                    command_seq(92):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(93):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(94):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(96):=(clr_sr ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(w_disable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(100):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(w_sr  ,none      ,1,0,0,0,16#10#,0,0,valid,0 ns);
                    command_seq(103):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(105):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(107):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(108):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 0 to 31 are locked
                    command_seq(109):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(110):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(111):=(pg_prog4,none   ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(112):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(113):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(114):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(116):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(118):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(119):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(120):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(121):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(122):=(pg_prog4,none   ,5,0,0,0,16#99#,31,10,valid,0 ns);
                    command_seq(123):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(124):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(125):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(127):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(128):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(129):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(131):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(132):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(133):=(w_sr  ,none     ,1,0,0,0,16#14#,0,0,valid,0 ns);
                    command_seq(134):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(135):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(136):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(137):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(138):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(139):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 0 to 63 are locked
                    command_seq(140):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(141):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(142):=(pg_prog4,none   ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(143):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(144):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(145):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(147):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(149):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(150):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(151):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(152):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(153):=(pg_prog4,none   ,5,0,0,0,16#99#,63,10,valid,0 ns);
                    command_seq(154):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(155):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(156):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(157):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(158):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(159):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(160):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(161):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(162):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(163):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(164):=(w_sr  ,none     ,1,0,0,0,16#18#,0,0,valid,0 ns);
                    command_seq(165):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(166):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(167):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(168):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(169):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(170):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    --Sectors from 0 to 127 are locked
                    command_seq(171):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(172):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(173):=(pg_prog4,none   ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(174):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(175):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(176):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(178):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(180):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(181):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(182):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(183):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(184):=(pg_prog4,none   ,5,0,0,0,16#99#,127,10,valid,0 ns);
                    command_seq(185):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(186):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(187):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(188):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(189):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(190):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(191):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(192):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(193):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(194):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(195):=(w_sr   ,none    ,1,0,0,0,16#1C#,0,0,valid,0 ns);
                    command_seq(196):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(197):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(198):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(199):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(200):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(201):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --All sectors are locked
                    command_seq(202):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(203):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(204):=(pg_prog4,none   ,5,0,0,0,16#99#,0,60,valid,0 ns);
                    command_seq(205):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(206):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(207):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(208):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(209):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(210):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(211):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(212):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(213):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(214):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(215):=(pg_prog4,none   ,5,0,0,0,16#99#,255,10,valid,0 ns);
                    command_seq(216):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(217):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(218):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(219):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(220):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(221):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(222):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(223):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V is set to '0'
                    command_seq(224):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(225):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(226):=(wrar  ,none     ,1,0,0,0,16#00#,0,16#00800004#,valid,0 ns);
                    command_seq(227):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(228):=(wt     ,none    ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(229):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(230):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 4  =>
                    REPORT "Block protection, positive test";
                    -- TBPROT = '1'
                    ------------------------------------------------------------
                    -- Hybrid Architecture
                    ------------------------------------------------------------
                    command_seq(0) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(w_sr  ,none      ,1,0,0,0,16#04#,0,0,valid,0 ns);
                    command_seq(4) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(8) :=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 0 to 3 are locked
                        command_seq(10):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(17):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(pg_prog4,none    ,5,0,0,0,16#99#,3,10,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(25):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(26):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(28):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(30):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 11 are locked
                        command_seq(10):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(17):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(pg_prog4,none    ,5,0,0,0,16#99#,11,10,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(25):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(26):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(28):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(30):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(32):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(w_sr  ,none      ,1,0,0,0,16#08#,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(39):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 0 to 7 are locked
                        command_seq(41):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(42):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(43):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(44):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(45):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(46):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(48):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(49):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(50):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(54):=(pg_prog4,none    ,5,0,0,0,16#99#,7,10,valid,0 ns);
                        command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(57):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(59):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(61):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(62):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 15 are locked
                        command_seq(41):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(42):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(43):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(44):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(45):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(46):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(48):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(49):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(50):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(54):=(pg_prog4,none    ,5,0,0,0,16#99#,15,10,valid,0 ns);
                        command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(57):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(59):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(61):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(62):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(63):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(w_sr  ,none      ,1,0,0,0,16#0C#,0,0,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(69):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(70):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 20 to 15 are locked
                        command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(74):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(77):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(78):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(79):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(80):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(81):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(82):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(83):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(84):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(85):=(pg_prog4,none    ,5,0,0,0,16#99#,15,10,valid,0 ns);
                        command_seq(86):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(87):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(88):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(89):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(90):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(91):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(92):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 23 are locked
                        command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(74):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(77):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(78):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(79):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(80):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(81):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(82):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(83):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(84):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(85):=(pg_prog4,none    ,5,0,0,0,16#99#,23,10,valid,0 ns);
                        command_seq(86):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(87):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(88):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(89):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(90):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(91):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(92):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(94):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(w_sr  ,none      ,1,0,0,0,16#10#,0,0,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(101):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 0 to 31 are locked
                        command_seq(103):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(104):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(105):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(106):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(107):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(108):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(109):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(110):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(111):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(112):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(113):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(114):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(116):=(pg_prog4,none    ,5,0,0,0,16#99#,31,10,valid,0 ns);
                        command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(118):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(119):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(120):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(121):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(122):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(123):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(124):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 39 are locked
                        command_seq(103):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(104):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(105):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(106):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(107):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(108):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(109):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(110):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(111):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(112):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(113):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(114):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(115):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(116):=(pg_prog4,none    ,5,0,0,0,16#99#,39,10,valid,0 ns);
                        command_seq(117):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(118):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(119):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(120):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(121):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(122):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(123):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(124):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(125):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(127):=(w_sr  ,none      ,1,0,0,0,16#14#,0,0,valid,0 ns);
                    command_seq(128):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(129):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(131):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(132):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(133):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 0to 63 are locked
                        command_seq(134):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(135):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(136):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(137):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(138):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(139):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(140):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(141):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(142):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(143):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(144):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(145):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(147):=(pg_prog4,none    ,5,0,0,0,16#99#,63,10,valid,0 ns);
                        command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(149):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(150):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(151):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(152):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(153):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(154):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(155):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 71 are locked
                        command_seq(134):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(135):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(136):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(137):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(138):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(139):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(140):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(141):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(142):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(143):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(144):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(145):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(146):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(147):=(pg_prog4,none    ,5,0,0,0,16#99#,71,10,valid,0 ns);
                        command_seq(148):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(149):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(150):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(151):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(152):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(153):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(154):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(155):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(156):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(157):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(158):=(w_sr  ,none      ,1,0,0,0,16#18#,0,0,valid,0 ns);
                    command_seq(159):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(160):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(161):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(162):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(163):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(164):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN --TopBoot
                        --Sectors from 0 to 127 are locked
                        command_seq(165):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(166):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(167):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(168):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(169):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(170):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(171):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(172):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(173):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(174):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(175):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(176):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(178):=(pg_prog4,none    ,5,0,0,0,16#99#,127,10,valid,0 ns);
                        command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(180):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(181):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(182):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(183):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(184):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(185):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(186):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE -- BottomBoot
                        --Sectors from 0 to 135 are locked
                        command_seq(165):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(166):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(167):=(pg_prog4,none    ,5,0,0,0,16#99#,0,60,valid,0 ns);
                        command_seq(168):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(169):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(170):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(171):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(172):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(173):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(174):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(175):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(176):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(177):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(178):=(pg_prog4,none    ,5,0,0,0,16#99#,135,10,valid,0 ns);
                        command_seq(179):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- When P_ERR is set to to "1", the WIP bit will remain set to
                        -- one indicationg the device remains busy and unable to receive
                        -- most new operation commands.
                        command_seq(180):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(181):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(182):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- A Clear Status Register followed by Write Disable command must
                        -- be sent to return device to standby state
                        command_seq(183):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(184):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(185):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(186):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    command_seq(187):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(188):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(189):=(w_sr  ,none      ,1,0,0,0,16#1C#,0,0,valid,0 ns);
                    command_seq(190):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(191):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(192):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(193):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(194):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(195):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --All sectors are locked
                    command_seq(196):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(197):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(198):=(pg_prog4,none    ,5,0,0,0,16#99#,0,20,valid,0 ns);
                    command_seq(199):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(200):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(201):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(202):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(203):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(204):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(205):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(206):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(207):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(208):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(209):=(pg_prog4,none   ,5,0,0,0,16#99#,263,10,valid,0 ns);
                    command_seq(210):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(211):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(212):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(213):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(214):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(215):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(216):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(217):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --All sectors are unlocked
                    command_seq(218):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(219):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(220):=(w_sr  ,none      ,1,0,0,0,16#00#,0,0,valid,0 ns);
                    command_seq(221):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(222):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(223):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(224):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(225):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(226):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(227):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 6  =>  --Initial configuration test (TBPROT)
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "TBPROT bit negative test";
                    --If TBPROT is programmed to 1, an attempt to change it back
                    --to zero will be ignored and no error is set.
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(4) :=(w_scr  ,none      ,2,0,0,0,16#0024#,0,0,valid,0 ns);
                    ELSE
                        command_seq(4) :=(w_scr  ,none      ,2,0,0,0,16#0020#,0,0,valid,0 ns);
                    END IF;
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that operation is not accepted
                    command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that P_ERR bit is not set
                    command_seq(10) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that TBPROT did not change its value
                    command_seq(12):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
					--Verify 3/4 Byte addressing for rdar
					command_seq(17) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(20):=(wrar   ,none  ,1,0,0,0,16#88#,0,16#00800003#,valid,0 ns);
					command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(24):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(26) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(29):=(wrar   ,none  ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
					command_seq(30):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(32):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(33):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 7  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "READ, positive tests";
                    ------------------------------------------------------------
                    -- Wrap Disabled, QUAD ALL = '0'
                    ------------------------------------------------------------
                    -- 3 Bytes address and AL = '0'
                    -- Normal Read
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rd     ,read     ,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rd     ,read     ,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(6) :=(fast_rd,read_fast,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(fast_rd,read_fast,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(10):=(dual_high_rd,read_dual_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(dual_high_rd,read_dual_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Enter Quad Read Mode
                    command_seq(14):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(16):=(wrar  ,none     ,1,0,0,0,16#26#,0,16#00800002#,valid,0 ns);
                    ELSE
                        command_seq(16):=(wrar  ,none     ,1,0,0,0,16#22#,0,16#00800002#,valid,0 ns);
                    END IF;
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that QUAD bit is set (CR1V(1))
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad Output Read
                    command_seq(22)  :=(quad_rd,rd_quad,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24)  :=(quad_rd,rd_quad,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(25)  :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad Output Read 4
                    command_seq(26)  :=(quad_rd_4,rd_quad_4,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(27):=(idle   ,none         ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28)  :=(quad_rd_4,rd_quad_4,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(29)  :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(30):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,clock_num,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(34):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    -- Wrap Enabled, QUAD ALL = '0'
                    -- 3 Bytes address and AL = '0'
                    ------------------------------------------------------------

                    -- Enter Wrap Mode, Wrap Length = 8
                    command_seq(38):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800005#,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Wrap Enable bit is set (CR4V(4))
                    command_seq(44):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(45):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Normal Read
                    -- Verify that Read command is no affected by Wrap Enable
                    command_seq(46):=(rd     ,read     ,8,0,0,0,0,1,4,valid,0 ns);
                    command_seq(47):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(rd     ,read     ,8,0,0,0,0,2,11,valid,0 ns);
                    command_seq(49):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(50):=(fast_rd,read_fast,16,0,0,0,0,1,4,valid,0 ns);
                    command_seq(51):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(fast_rd,read_fast,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(54):=(dual_high_rd,read_dual_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(dual_high_rd,read_dual_hi,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enter Quad Read Mode
                    command_seq(58):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(60):=(wrar  ,none     ,1,0,0,0,16#26#,0,16#00800002#,valid,0 ns);
                    ELSE
                        command_seq(60):=(wrar  ,none     ,1,0,0,0,16#22#,0,16#00800002#,valid,0 ns);
                    END IF;
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(63):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that QUAD bit is set (CR1V(1))
                    command_seq(64):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(65):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(66):=(quad_high_rd,read_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(67):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(quad_high_rd,read_quad_hi,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(69):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(70):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(73):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 16
                    command_seq(74):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(wrar  ,none      ,1,0,0,0,16#11#,0,16#00800005#,valid,0 ns);
                    command_seq(77):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(79):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(82):=(fast_rd,read_fast,32,0,0,0,0,1,4,valid,0 ns);
                    command_seq(83):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(fast_rd,read_fast,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(85):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(86):=(dual_high_rd,read_dual_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(87):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(dual_high_rd,read_dual_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(89):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(90):=(quad_high_rd,read_quad_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(quad_high_rd,read_quad_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(93):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(94):=(quad_high_ddr_rd,read_ddr_quad_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(quad_high_ddr_rd,read_ddr_quad_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 32
                    command_seq(98):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(wrar  ,none      ,1,0,0,0,16#12#,0,16#00800005#,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(103):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(105):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(106):=(fast_rd,read_fast,64,0,0,0,0,1,4,valid,0 ns);
                    command_seq(107):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(108):=(fast_rd,read_fast,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(109):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(110):=(dual_high_rd,read_dual_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(111):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(112):=(dual_high_rd,read_dual_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(113):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(114):=(quad_high_rd,read_quad_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(115):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(116):=(quad_high_rd,read_quad_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(117):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(118):=(quad_high_ddr_rd,read_ddr_quad_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(119):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(120):=(quad_high_ddr_rd,read_ddr_quad_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(121):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 64
                    command_seq(122):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(123):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(124):=(wrar  ,none      ,1,0,0,0,16#13#,0,16#00800005#,valid,0 ns);
                    command_seq(125):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(127):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(128):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(129):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(130):=(fast_rd,read_fast,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(131):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(132):=(fast_rd,read_fast,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(133):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(134):=(dual_high_rd,read_dual_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(135):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(136):=(dual_high_rd,read_dual_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(137):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(138):=(quad_high_rd,read_quad_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(139):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(140):=(quad_high_rd,read_quad_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(141):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(142):=(quad_high_ddr_rd,read_ddr_quad_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(143):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(144):=(quad_high_ddr_rd,read_ddr_quad_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(145):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Disabled, Wrap Length = 8
                    command_seq(146):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(147):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(148):=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800005#,valid,0 ns);
                    command_seq(149):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(150):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(151):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(152):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(153):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(154):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "READ, positive tests";
                    ------------------------------------------------------------
                    -- Wrap Disabled, QUAD ALL = '0'
                    ------------------------------------------------------------
                    -- Set Address Length to '1'
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#88#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 3 Bytes address and AL = '1'
                    -- Normal Read
                    command_seq(10):=(rd     ,read     ,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rd     ,read     ,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(14):=(rd     ,read     ,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(14):=(rd     ,read     ,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Fast Read
                    command_seq(16):=(fast_rd,read_fast,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(fast_rd,read_fast,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(20):=(fast_rd,read_fast,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(20):=(fast_rd,read_fast,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Dual I/O High Performance Read Mode
                    command_seq(22):=(dual_high_rd,read_dual_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(dual_high_rd,read_dual_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(26):=(dual_high_rd,read_dual_hi,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(26):=(dual_high_rd,read_dual_hi,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O High Performance Read Mode
                    command_seq(28):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,clock_num,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(32):=(quad_high_rd,read_quad_hi,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(32):=(quad_high_rd,read_quad_hi,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O DDR Read Mode
                    command_seq(34):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(38):=(quad_high_ddr_rd,read_ddr_quad_hi,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(38):=(quad_high_ddr_rd,read_ddr_quad_hi,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    ------------------------------------------------------------
                    -- Wrap Enabled, QUAD ALL = '0'
                    -- 3 Bytes address and AL = '1'
                    ------------------------------------------------------------
                    -- Enter Wrap Mode, Wrap Length = 8
                    command_seq(40):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800005#,valid,0 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(45):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Wrap Enable bit is set (CR4V(4))
                    command_seq(46):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(47):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Normal Read
                    -- Verify that Read command is no affected by Wrap Enable
                    command_seq(48):=(rd     ,read     ,8,0,0,0,0,1,4,valid,0 ns);
                    command_seq(49):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(rd     ,read     ,8,0,0,0,0,2,11,valid,0 ns);
                    command_seq(51):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(52):=(fast_rd,read_fast,16,0,0,0,0,1,4,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(54):=(fast_rd,read_fast,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                        command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(54):=(fast_rd,read_fast,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                        command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    -- Dual I/O High Performance Read Mode
                    command_seq(56):=(dual_high_rd,read_dual_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(58):=(dual_high_rd,read_dual_hi,16,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(58):=(dual_high_rd,read_dual_hi,16,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enter Quad Read Mode
                    command_seq(60):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(62):=(wrar  ,none     ,1,0,0,0,16#26#,0,16#00800002#,valid,0 ns);
                    ELSE
                        command_seq(62):=(wrar  ,none     ,1,0,0,0,16#22#,0,16#00800002#,valid,0 ns);
                    END IF;
                    command_seq(63):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(65):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that QUAD bit is set (CR1V(1))
                    command_seq(66):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(67):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(68):=(quad_high_rd,read_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(69):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(70):=(quad_high_rd,read_quad_hi,16,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(70):=(quad_high_rd,read_quad_hi,16,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(72):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(73):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(74):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(74):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(75):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 16
                    command_seq(76):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(wrar  ,none      ,1,0,0,0,16#11#,0,16#00800005#,valid,0 ns);
                    command_seq(79):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(83):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(84):=(fast_rd,read_fast,32,0,0,0,0,1,4,valid,0 ns);
                    command_seq(85):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(fast_rd,read_fast,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(87):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(88):=(dual_high_rd,read_dual_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(89):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(dual_high_rd,read_dual_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(92):=(quad_high_rd,read_quad_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(93):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(94):=(quad_high_rd,read_quad_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(96):=(quad_high_ddr_rd,read_ddr_quad_hi,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(quad_high_ddr_rd,read_ddr_quad_hi,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 32
                    command_seq(100):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(wrar  ,none      ,1,0,0,0,16#12#,0,16#00800005#,valid,0 ns);
                    command_seq(103):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(105):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(107):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(108):=(fast_rd,read_fast,64,0,0,0,0,1,4,valid,0 ns);
                    command_seq(109):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(110):=(fast_rd,read_fast,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(111):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(112):=(dual_high_rd,read_dual_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(113):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(114):=(dual_high_rd,read_dual_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(115):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(116):=(quad_high_rd,read_quad_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(117):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(118):=(quad_high_rd,read_quad_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(119):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(120):=(quad_high_ddr_rd,read_ddr_quad_hi,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(121):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(122):=(quad_high_ddr_rd,read_ddr_quad_hi,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(123):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Enabled, Wrap Length = 64
                    command_seq(124):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(125):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(126):=(wrar  ,none      ,1,0,0,0,16#13#,0,16#00800005#,valid,0 ns);
                    command_seq(127):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(128):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(129):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(131):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(132):=(fast_rd,read_fast,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(133):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(134):=(fast_rd,read_fast,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(135):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(136):=(dual_high_rd,read_dual_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(137):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(138):=(dual_high_rd,read_dual_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(139):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(140):=(quad_high_rd,read_quad_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(141):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(142):=(quad_high_rd,read_quad_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(143):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(144):=(quad_high_ddr_rd,read_ddr_quad_hi,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(145):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(146):=(quad_high_ddr_rd,read_ddr_quad_hi,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(147):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Disabled, Wrap Length = 8
                    command_seq(148):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(149):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(150):=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800005#,valid,0 ns);
                    command_seq(151):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(152):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(153):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(154):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(155):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Setting up Address Length bit to '0'
                    command_seq(156):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(157):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(158):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(159):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(160):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(161):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(162):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(163):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(164):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "READ, positive tests";
                    -- 4 Bytes address
                    -- Normal Read
                    command_seq(1) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rd_4   ,read_4      ,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rd_4   ,read_4      ,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(6) :=(fast_rd4,read_fast_4,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(fast_rd4,read_fast_4,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(9) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(10):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Verify that QUAD bit is set (CR1V(1))
                    command_seq(14):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(16):=(quad_high_rd_4,read_quad_hi4,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(quad_high_rd_4,read_quad_hi4,5,0,0,0,0,1,0,clock_num,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(20):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    -- Wrap Enabled, QUAD ALL = '0'
                    -- 4 Bytes address and AL = '0'
                    ------------------------------------------------------------

--                     -- Enter Wrap Mode, Wrap Length = 8
--                     command_seq(24):=(set_bl,none      ,1,0,0,0,16#10#,0,0,valid,0 ns);
--                     command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enter Wrap Mode, Wrap Length = 8
                    command_seq(24):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800005#,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Wrap Enable bit is '0' (CR4V(4))
                    command_seq(30):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Normal Read
                    -- Verify that Read command is no affected by Wrap Enable
                    command_seq(32):=(rd     ,read     ,8,0,0,0,0,1,4,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(rd     ,read     ,8,0,0,0,0,2,11,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(36):=(fast_rd4,read_fast_4,16,0,0,0,0,1,4,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(fast_rd4,read_fast_4,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(40):=(dual_high_rd_4,read_dual_hi4,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(dual_high_rd_4,read_dual_hi4,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Verify that QUAD bit is set (CR1V(1))
                    command_seq(44):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(45):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(46):=(quad_high_rd_4,read_quad_hi4,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(47):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(quad_high_rd_4,read_quad_hi4,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(49):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(50):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(51):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

--                     -- Wrap Mode Enabled, Wrap Length = 16
--                     command_seq(54):=(set_bl,none      ,1,0,0,0,16#11#,0,0,valid,0 ns);
--                     command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Wrap Mode Enabled, Wrap Length = 16
                    command_seq(54):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(wrar  ,none      ,1,0,0,0,16#11#,0,16#00800005#,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that correct data is written
                    command_seq(60):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(62):=(fast_rd4,read_fast_4,32,0,0,0,0,1,4,valid,0 ns);
                    command_seq(63):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(fast_rd4,read_fast_4,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(66):=(dual_high_rd_4,read_dual_hi4,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(67):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(dual_high_rd_4,read_dual_hi4,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(69):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(70):=(quad_high_rd_4,read_quad_hi4,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(quad_high_rd_4,read_quad_hi4,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(73):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(74):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,32,0,0,0,0,1,5,valid,0 ns);
                    command_seq(75):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,32,0,0,0,0,2,11,valid,0 ns);
                    command_seq(77):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

--                     -- Wrap Mode Enabled, Wrap Length = 32
--                     command_seq(70):=(set_bl,none      ,1,0,0,0,16#12#,0,0,valid,0 ns);
--                     command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Wrap Mode Enabled, Wrap Length = 32
                    command_seq(78):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(wrar  ,none      ,1,0,0,0,16#12#,0,16#00800005#,valid,0 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(83):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that correct data is written
                    command_seq(84):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(85):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(86):=(fast_rd4,read_fast_4,64,0,0,0,0,1,4,valid,0 ns);
                    command_seq(87):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(fast_rd4,read_fast_4,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(89):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(90):=(dual_high_rd_4,read_dual_hi4,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(dual_high_rd_4,read_dual_hi4,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(93):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(94):=(quad_high_rd_4,read_quad_hi4,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(quad_high_rd_4,read_quad_hi4,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(98):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,64,0,0,0,0,1,5,valid,0 ns);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,64,0,0,0,0,2,11,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

--                     -- Wrap Mode Enabled, Wrap Length = 64
--                     command_seq(90):=(set_bl,none      ,1,0,0,0,16#13#,0,0,valid,0 ns);
--                     command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Wrap Mode Enabled, Wrap Length = 64
                    command_seq(102):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(103):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(wrar  ,none      ,1,0,0,0,16#13#,0,16#00800005#,valid,0 ns);
                    command_seq(105):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(107):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that correct data is written
                    command_seq(108):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(109):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(110):=(fast_rd4,read_fast_4,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(111):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(112):=(fast_rd4,read_fast_4,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(113):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(114):=(dual_high_rd_4,read_dual_hi4,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(115):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(116):=(dual_high_rd_4,read_dual_hi4,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(117):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(118):=(quad_high_rd_4,read_quad_hi4,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(119):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(120):=(quad_high_rd_4,read_quad_hi4,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(121):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(122):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,80,0,0,0,0,1,0,valid,0 ns);
                    command_seq(123):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(124):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,80,0,0,0,0,2,0,valid,0 ns);
                    command_seq(125):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

--                     -- Wrap Mode Disabled, Wrap Length = 8
--                     command_seq(110):=(set_bl,none      ,1,0,0,0,16#00#,0,0,valid,0 ns);
--                     command_seq(111):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Wrap Mode Disabled, Wrap Length = 8
                    command_seq(126):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(127):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(128):=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800005#,valid,0 ns);
                    command_seq(129):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(130):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(131):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Wrap Enable bit is '0' (CR4V(4))
                    command_seq(132):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(133):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Exit Quad Read Mode
                    command_seq(134):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(135):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(136):=(wrar  ,none     ,1,0,0,0,16#24#,0,16#00800002#,valid,0 ns);
                    ELSE
                        command_seq(136):=(wrar  ,none     ,1,0,0,0,16#20#,0,16#00800002#,valid,0 ns);
                    END IF;
                    command_seq(137):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(138):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(139):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(140):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(141):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(142):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 4  =>
                    REPORT "QUAD ALL READ, positive tests";
                    -- Enter Quad All Mode
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that QA bit is set
                    command_seq(8) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that QUAD bit is set
                    command_seq(10):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    -- Wrap Disabled, QUAD ALL = '1'
                    -- 3 Bytes address and AL = '0'
                    ------------------------------------------------------------
                    -- Quad I/O High Performance Read Mode
                    command_seq(12):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,clock_num,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(16):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    -- Wrap Enabled, QUAD ALL = '1'
                    -- 3 Bytes address and AL = '0'
                    ------------------------------------------------------------
                    -- Enter Wrap Mode, Wrap Length = 8
                    command_seq(20):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800005#,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Wrap Enable bit is set (CR4V(4))
                    command_seq(26):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O High Performance Read Mode
                    command_seq(28):=(quad_high_rd,read_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(quad_high_rd,read_quad_hi,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(32):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,1,5,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(quad_high_ddr_rd,read_ddr_quad_hi,16,0,0,0,0,2,11,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Wrap Mode Disabled, Wrap Length = 8
                    command_seq(36):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800005#,valid,0 ns);
                    command_seq(39):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set Address Length to '1'
                    command_seq(44):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(wrar  ,none      ,1,0,0,0,16#C8#,0,16#00800003#,valid,0 ns);
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(52):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O High Performance Read Mode
                    command_seq(53):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(54):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(quad_high_rd,read_quad_hi,5,0,0,0,0,1,0,clock_num,0 ns);
                    command_seq(56):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(57):=(quad_high_rd,read_quad_hi,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(57):=(quad_high_rd,read_quad_hi,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(58):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O DDR Read Mode
                    command_seq(59):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,valid,0 ns);
                    command_seq(60):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(quad_high_ddr_rd,read_ddr_quad_hi,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(62):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(63):=(quad_high_ddr_rd,read_ddr_quad_hi,8,0,0,0,0,263,16#FFA#,valid,0 ns);
                    ELSE
                        command_seq(63):=(quad_high_ddr_rd,read_ddr_quad_hi,8,0,0,0,0,263,16#FFFA#,valid,0 ns);
                    END IF;
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    -- Fast Read
                    command_seq(65) :=(fast_rd4,read_fast_4,5,0,0,0,0,1,0,valid,0 ns);
                    command_seq(66) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67) :=(fast_rd4,read_fast_4,5,0,0,0,0,1,5,clock_num,0 ns);
                    command_seq(68) :=(idle   ,none        ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set Address Length and QA bits to '0'
                    command_seq(69):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(72):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(74):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(76):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 5  =>
                    REPORT "READ - Continuous Mode, positive tests";
                    command_seq(1):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 3 Bytes address and AL = '0'
                    -- dual high performance read - Initial access, mode bits are Axh
                    command_seq(2):=(dual_high_rd,read_dual_hi,5,0,0,0,16#A0#,0,0,valid,0 ns);
                    command_seq(3):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous dual high performance read - Subsequent access
                    command_seq(4):=(dual_high_rd,rd_cont_dualIO,5,0,0,0,0,1,1,break,0 ns);
                    command_seq(5):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    -- dual high performance read - Initial access, mode bits are Axh
                    command_seq(6):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,16#A0#,0,0,valid,0 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(dual_high_rd_4,rd_cont_dualIO4,5,0,0,0,0,1,1,break,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- quad high performance read - Initial access, mode bits are Axh
                    command_seq(10):=(quad_high_rd,read_quad_hi,5,0,0,0,16#A0#,1,0,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous quad high performance read - Subsequent access
                    command_seq(12):=(quad_high_rd,rd_cont_quadIO,5,0,0,0,0,1,0,break,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    -- quad high performance read - Initial access, mode bits are Axh
                    command_seq(14):=(quad_high_rd_4,read_quad_hi4,5,0,0,0,16#A0#,1,0,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous quad high performance read - Subsequent access
                    command_seq(16):=(quad_high_rd_4,rd_cont_quadIO4,5,0,0,0,0,1,0,break,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    -- dual high performance read - Initial access, mode bits are Axh
                    command_seq(18):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,16#A0#,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(dual_high_rd_4,rd_cont_dualIO4,5,0,0,0,0,1,1,break,0 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    -- fast performance read - Initial access, mode bits are Axh
                    command_seq(22):=(fast_rd4,read_fast_4,5,0,0,0,16#A0#,0,1,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous fast performance read - Subsequent access
                    command_seq(24):=(fast_rd4,read_fast_4_IO,5,0,0,0,0,0,4,break,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    -- DDR QIOR read - Initial access, mode bits are Axh
                    command_seq(26):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,16#A5#,0,1,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous fast performance read - Subsequent access
                    command_seq(28):=(quad_high_ddr_rd_4,rd_cont_qddr4,5,0,0,0,0,0,4,break,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    
                    
                    
                    --Initiate MBR command to release from Continuous Read
                    command_seq(30):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    
--                      command_seq(22):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
--                      command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                      command_seq(24):=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 8  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "READ Status Register1, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR1 ,none,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(6) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(14):=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(16):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "READ Status Register2, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "READ Configuration Register, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 4  =>
                    REPORT "READ ASP Register, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000031#,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 5  =>
                    REPORT "READ Password Register, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rdar_read,read_rdar,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000021#,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 6  =>
                    REPORT "READ PPB Lock Register, positive tests";
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 7  =>
                    REPORT "READ Access Registers, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(ppbacc_rd,read_ppbar,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppbacc_rd,read_ppbar,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(ppbacc_rd4,read_ppbar_4,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(ppbacc_rd4,read_ppbar_4,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10) :=(dybacc_rd,read_dybar,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(dybacc_rd,read_dybar,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(dybacc_rd4,read_dybar_4,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(15) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(dybacc_rd4,read_dybar_4,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(17) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(18):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(26):=(dybacc_rd,read_dybar,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(dybacc_rd4,read_dybar_4,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(30):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 8  =>
                    REPORT "READ ECC Register, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(ecc_read,read_ecc,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ecc_read,read_ecc,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(ecc_read4,read_ecc_4,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(ecc_read4,read_ecc_4,2,0,0,0,0,1,19,clock_num,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(10):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(18):=(ecc_read,read_ecc,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ecc_read4,read_ecc_4,2,0,0,0,0,1,19,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(22):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 9  =>
                    REPORT "READ VDLR Register, positive tests";
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 10  =>
                    REPORT "Read Any Register, positive tests";
                    --Read SR1NV
                    command_seq(1) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(rdar_read,read_rdar ,2,0,0,0,0,0,0,valid,0 ns);
                    --Reading undefined locations provides undefined data
                    command_seq(3) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(rdar_read,rd_U      ,2,0,0,0,0,0,1,valid,0 ns);
                    --Read CR1NV
                    command_seq(5) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(rdar_read,read_rdar ,2,0,0,0,0,0,2,valid,0 ns);
                    --Read CR2NV
                    command_seq(7) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(rdar_read,read_rdar ,2,0,0,0,0,0,3,valid,0 ns);
                    --Read CR3NV
                    command_seq(9) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(rdar_read,read_rdar ,2,0,0,0,0,0,4,valid,0 ns);
                    --Read CR4NV
                    command_seq(11):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rdar_read,read_rdar ,2,0,0,0,0,0,5,valid,0 ns);
                    --Reading undefined locations provides undefined data
                    command_seq(13):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(rdar_read , rd_U    ,2,0,0,0,0,0,6,valid,0 ns);
                    --Read NVDLR
                    command_seq(15):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(rdar_read,read_rdar ,2,0,0,0,0,0,16#10#,valid,0 ns);
                    --Read Password Register
                    command_seq(17):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#20#,valid,0 ns);
                    command_seq(19):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#21#,valid,0 ns);
                    command_seq(21):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#22#,valid,0 ns);
                    command_seq(23):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#23#,valid,0 ns);
                    command_seq(25):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#24#,valid,0 ns);
                    command_seq(27):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#25#,valid,0 ns);
                    command_seq(29):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#26#,valid,0 ns);
                    command_seq(31):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#27#,valid,0 ns);
                    --Read ASP Register
                    command_seq(33):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#30#,valid,0 ns);
                    command_seq(35):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#31#,valid,0 ns);
                    --Read SR1V
                    command_seq(37):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800000#,valid,0 ns);
                    --Read SR2V
                    command_seq(39):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800001#,valid,0 ns);
                    --Read CR1V
                    command_seq(41):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800002#,valid,0 ns);
                    --Read CR2V
                    command_seq(43):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800003#,valid,0 ns);
                    --Read CR3V
                    command_seq(45):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800004#,valid,0 ns);
                    --Read CR4V
                    command_seq(47):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800005#,valid,0 ns);
                    --Read VDLR
                    command_seq(49):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#800010#,valid,0 ns);
                    --Read PPBL
                    command_seq(51):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#80009B#,valid,0 ns);
                    command_seq(53):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(done     ,none      ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 9  =>
                REPORT "OTP READ, positive test";
                command_seq(1):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(2):=(otp_read,read_otp ,3,0,0,0,0,0,16#020#,valid,0 ns);
                command_seq(3):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(4):=(otp_read,read_otp,3,0,0,0,0,0,16#3FC#,valid,0 ns);
                command_seq(5):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(6):=(otp_read,rd_U ,1,0,0,0,0,0,16#400#,valid,0 ns);
                command_seq(7):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(8):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

            WHEN 10  =>
                CASE Testcase IS
                    -- Read ID Tests
                    WHEN 1  =>
                    REPORT "READ Jedec ID, positive test";
                    command_seq(1)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2)  :=(read_JID,none   ,24,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4)  :=(read_JID,none   ,24,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(5)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(6) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(11):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(14):=(read_JID,none   ,24,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(16):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "READ Quad Jedec ID, positive test";
                    command_seq(1)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4):=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_JQID,none   ,81,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(read_JQID,none  ,85,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "READ SFDP and UID, positive test";
                    --cmd,sts,byte_num,data4,data3,data2,data1,sect,addr,aux_t,time
                    -- QUAD ALL mode
                    command_seq(1)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that QA bit is set
                    command_seq(2) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SFDP,none   ,1,0,0,0,0,0,16#200#,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SFDP,none  ,16#124#,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(read_RUID,none  ,16#4#,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(10) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(18):=(read_SFDP,none  ,16#124#,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(20):=(read_RUID,none  ,16#4#,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 11  =>
--                 REPORT "WRAR test SR1V[4]";
--                 command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(3) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
--                 command_seq(4) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(6) :=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800000#,valid,0 ns);
--                 command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(8) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                 command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(10) :=(read_SR1 ,rd_SR1 ,1,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(11) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(12) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
--                 command_seq(13) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                 command_seq(14) :=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                
                REPORT "WRAR test SR1V[4], QPI";
                command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                command_seq(10) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);    
                command_seq(11) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(13) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                command_seq(14) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(15) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(16) :=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800000#,valid,0 ns);
                command_seq(17) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(18) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                command_seq(19) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(20) :=(read_SR1 ,rd_SR1 ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(21) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(22) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                command_seq(23) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                -- Set QA bit to '0'
                command_seq(24) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(25) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(26):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(28):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(30):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(32):=(done   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
               


            WHEN 12  =>
                REPORT "4BAM and 4BAX command, positive test";
                command_seq(1) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                --Verify that Address is 3 Bytes in length
                command_seq(2) :=(fast_rd,read_fast  ,4,0,0,0,0,1,0,valid,0 ns);
                command_seq(3) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(4) :=(otp_read,read_otp  ,4,0,0,0,0,0,0,valid,0 ns);
                command_seq(5) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                -- Set AL to 1

                command_seq(6) :=(bam4   ,none       ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(7) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                -- Verify that AL bit is set(CR2V(7))
                command_seq(8) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(9) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                -- Verify that WEL bit is still "1"
                command_seq(10):=(read_SR1 ,rd_wel_0   ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(11):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                --Verify that Address is 4 Bytes in length
                command_seq(12):=(fast_rd,read_fast  ,4,0,0,0,0,1,0,valid,0 ns);
                command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(14):=(otp_read,read_otp  ,4,0,0,0,0,0,0,valid,0 ns);
                command_seq(15):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(16):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                
                command_seq(17) :=(bax4   ,none       ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(18) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                
                command_seq(19) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                --Verify that Address is 3 Bytes in length
                command_seq(20) :=(fast_rd,read_fast  ,4,0,0,0,0,1,0,valid,0 ns);
                command_seq(21) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                command_seq(22) :=(otp_read,read_otp  ,4,0,0,0,0,0,0,valid,0 ns);
                command_seq(23) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                
                command_seq(24) :=(bam4   ,none       ,1,0,0,0,0,0,0,valid,0 ns);
                command_seq(25) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                -- Verify that AL bit is set(CR2V(7))
                command_seq(26) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                command_seq(27) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
             
            WHEN 13  =>
                CASE Testcase IS	
--                     REPORT "Programming NVDLR/VDLR,";
--                     REPORT "reading VDLR and reading memory data in DLP mode";
--                     command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(2) :=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(4) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(6) :=(w_nvldr,none     ,1,0,0,0,16#AA#,0,0,valid,0 ns);
--                     command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(8) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Read Status Register 2
--                     command_seq(10) :=(read_SR2 ,rd_SR2 ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(11) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Read Configuration Register
--                     command_seq(12) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Read Any Register Command
--                     command_seq(14):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
--                     command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     --Fast Read command is not allowed during Programming NVDLR
--                     command_seq(16):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
-- 
--                     command_seq(18):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tPP256);
--                     command_seq(19):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(20):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(21):=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(23):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(24):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(25):=(w_wvdlr,none     ,1,0,0,0,16#34#,0,0,valid,0 ns);
--                     command_seq(26):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(27):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(28):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(29):=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);
-- 
--                     -- Quad I/O DDR Read Mode
--                     command_seq(30):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(31):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Set Read Latency to 5
--                     command_seq(32):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(33):=(wrar  ,none      ,1,0,0,0,16#05#,0,16#00800003#,valid,0 ns);
--                     command_seq(34):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(35):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(37):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);
-- 
--                     -- Set Read Latency to 6
--                     command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(39):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(41):=(wrar  ,none      ,1,0,0,0,16#06#,0,16#00800003#,valid,0 ns);
--                     command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(43):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(44):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(45):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);
-- 
--                     -- Set Read Latency to 7
--                     command_seq(46):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(47):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(49):=(wrar  ,none      ,1,0,0,0,16#07#,0,16#00800003#,valid,0 ns);
--                     command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(51):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(52):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(53):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);
-- 
--                     -- Set Read Latency to 4
--                     command_seq(54):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(55):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(56):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(57):=(wrar  ,none      ,1,0,0,0,16#04#,0,16#00800003#,valid,0 ns);
--                     command_seq(58):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(59):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(60):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(61):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);
-- 
--                     command_seq(62):=(done   ,none      ,0,0,0,0,0,0,0,valid,0 ns);       
                WHEN 1  =>
                    REPORT "Programming NVDLR/VDLR, QPI";
                    REPORT "reading VDLR and reading memory data in DLP mode";
                    -- Set QA bit to '1'
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    command_seq(10) :=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);    
                    command_seq(11) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(rd_dlp ,read_dlp ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(w_nvldr,none     ,1,0,0,0,16#AA#,0,0,valid,0 ns);
                    command_seq(19) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Status Register 2
                    command_seq(22) :=(read_SR2 ,rd_SR2 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Configuration Register
                    command_seq(24) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register Command
                    command_seq(26):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Programming NVDLR
                    command_seq(28):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(30):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(w_wvdlr,none     ,1,0,0,0,16#34#,0,0,valid,0 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(read_SR1 ,none ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(rd_dlp ,read_dlp ,2,0,0,0,0,0,0,valid,0 ns);

                    -- Quad I/O DDR Read Mode
                    command_seq(46):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Set Read Latency to 5
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(wrar  ,none      ,1,0,0,0,16#05#,0,16#00800003#,valid,0 ns);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(52):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);

                    -- Set Read Latency to 6
                    command_seq(54):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(wrar  ,none      ,1,0,0,0,16#06#,0,16#00800003#,valid,0 ns);
                    command_seq(58):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(60):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);

                    -- Set Read Latency to 7
                    command_seq(62):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(wrar  ,none      ,1,0,0,0,16#07#,0,16#00800003#,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(69):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);

                    -- Set Read Latency to 4
                    command_seq(70):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(wrar  ,none      ,1,0,0,0,16#04#,0,16#00800003#,valid,0 ns);
                    command_seq(74):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(76):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,3,0,0,0,0,2,5,valid,0 ns);
                    -- Set QA bit to '0'
                    command_seq(78) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(81):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(83):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(85):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --command_seq(86):=(done   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
					command_seq(86) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- VRGLAT[1:0] Register Latency is set to '3'
                    command_seq(89) :=(wrar  ,none      ,1,0,0,0,16#c0#,0,16#00800004#,valid,0 ns);
                    command_seq(90) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(92) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					--Read CR3V
                    command_seq(93):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(94):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#00800005#,valid,0 ns);
					--RGLAT[1:0] Register Latency is set to '2'
					command_seq(95) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(97) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98) :=(wrar  ,none      ,1,0,0,0,16#80#,0,16#00800004#,valid,0 ns);
                    command_seq(99) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(101) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					--Read CR3V
                    command_seq(102):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(103):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#00800005#,valid,0 ns);
					command_seq(104):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					--RGLAT[1:0] Register Latency is set to '0'
					command_seq(105) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(107) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(108) :=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800004#,valid,0 ns);
                    command_seq(109) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(110) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(111) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
					--Read CR3V
                    command_seq(112):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(113):=(rdar_read,read_rdar ,1,0,0,0,0,0,16#00800005#,valid,0 ns);
					command_seq(114):=(done   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
			
                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 14  =>
                CASE Testcase IS
                    -- RSTEN + RST command set
                    WHEN 1  =>
                    REPORT "Software Reset, negative test";
                    -- The Reset Enable Command is required immediately before a
                    -- Reset command (RST). Any command other than RST following
                    -- the RSTEN command will clear the reset enable condition
                    -- and prevent a later RST command from being recognized.
                    command_seq(1) :=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(reset_en ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(w_enable ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(rst      ,err      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(fast_rd  ,read_fast,4,0,0,0,0,1,0,valid,0 ns);
                    command_seq(8) :=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(done     ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Software Reset, positive test";
                    -- The RST command immediately following a RSTEN command
                    -- initiates the software reset process.
                    command_seq(1) :=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR1NV
                    command_seq(2) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000002#,valid,0 ns);
                    command_seq(3) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR1V
                    command_seq(4) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(5) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR2V
                    command_seq(6) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(7) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR4V
                    command_seq(8) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(9) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read NVDLR
                    command_seq(10):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000010#,valid,0 ns);
                    command_seq(11):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read VDLR
                    command_seq(12):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800010#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V(4) is set to '1'
                    command_seq(16) :=(wrar  ,none      ,1,0,0,0,16#50#,0,16#00800004#,valid,0 ns);
                    command_seq(17) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(19) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CRFV3
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800004#,valid,0 ns);
                    command_seq(21):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A reset command is executed when CS# is brought high at
                    -- the end of instruction and requires tRH time to execute
                    command_seq(22):=(reset_en ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(rst      ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                   

                    command_seq(25):=(fast_rd  ,rd_HiZ   ,2,0,0,0,0,1,0,valid,0 ns);
                    command_seq(26):=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(27):=(wt     ,none      ,0,0,0,0,0,0,0,valid,2.5 ms);
                    
                     -- Read CRFV3
                    command_seq(28):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800004#,valid,0 ns);
                    command_seq(29):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Verify that the non-volatile bits in the configuration
                    -- register CR1NV (TBPROT_O, TBPARM_O) retain their previous
                    -- state
                    command_seq(30):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000002#,valid,0 ns);
                    command_seq(31):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that the Block Protection bits in the status
                    -- register SR1V are reseted to their default state
                    command_seq(32):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(33):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that CR2V bits are reseted to their default state
                    command_seq(34):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(35):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that CR4V bits are reseted to their default state
                    command_seq(36):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(37):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --After Reset vdlr value becomes nvldr value
                    command_seq(38):=(rd_dlp ,read_dlp   ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(done   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    
                    WHEN 3  =>
                    REPORT "Software Reset, positive test";
                    -- The RST command immediately following a RSTEN command
                    -- initiates the software reset process.
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    -- Read CR1NV
                    command_seq(10) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000002#,valid,0 ns);
                    command_seq(11) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR1V
                    command_seq(12) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR2V
                    command_seq(14) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(15) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR4V
                    command_seq(16) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(17) :=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read NVDLR
                    command_seq(18):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000010#,valid,0 ns);
                    command_seq(19):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read VDLR
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800010#,valid,0 ns);
                    command_seq(21):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V(4) is set to '1'
                    command_seq(24) :=(wrar  ,none      ,1,0,0,0,16#50#,0,16#00800004#,valid,0 ns);
                    command_seq(25) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(27) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CRFV3
                    command_seq(28):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800004#,valid,0 ns);
                    command_seq(29):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A reset command is executed when CS# is brought high at
                    -- the end of instruction and requires tRH time to execute
                    command_seq(30):=(reset_en ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(rst      ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    

                    command_seq(33):=(fast_rd  ,rd_HiZ   ,2,0,0,0,0,1,0,valid,0 ns);
                    command_seq(34):=(idle     ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(35):=(wt     ,none      ,0,0,0,0,0,0,0,valid,2.5 ms);
                    -- Read CRFV3
                    command_seq(36):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800004#,valid,0 ns);
                    command_seq(37):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    

                    -- Verify that the non-volatile bits in the configuration
                    -- register CR1NV (TBPROT_O, TBPARM_O) retain their previous
                    -- state
                    command_seq(38):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000002#,valid,0 ns);
                    command_seq(39):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that the Block Protection bits in the status
                    -- register SR1V are reseted to their default state
                    command_seq(40):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(41):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that CR2V bits are reseted to their default state
                    command_seq(42):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(43):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that CR4V bits are reseted to their default state
                    command_seq(44):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(45):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --After Reset vdlr value becomes nvldr value
                    command_seq(46):=(rd_dlp ,read_dlp   ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(done   ,none       ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 15  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "OTP program positive test";
                    -- Enabling bit walking
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#A0#,0,16#00800005#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that bit walking is enabled is set
                    command_seq(8) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Single Byte Programming
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(otp_prog,none ,1,0,0,0,16#AA#,0,16#300#,valid,0 ns);
                    command_seq(15) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(19) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(otp_read ,read_otp ,1,0,0,0,0,0,16#300#,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --  programming one byte, only in diferent location
                    command_seq(24):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(otp_prog,none ,1,0,0,0,16#88#,0,16#2E1#,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(31):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(otp_read ,read_otp ,1,0,0,0,0,0,16#2E1#,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- locking programed otp region
                    command_seq(36):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(otp_prog,none ,1,0,0,0,16#CC#,0,16#1C1#,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(45):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(otp_read ,read_otp ,1,0,0,0,0,0,16#1C1#,valid,0 ns);
                    command_seq(49):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(otp_prog,none ,1,0,0,0,16#9F#,0,16#11#,valid,0 ns);
                    command_seq(53):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(57):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(otp_read ,read_otp ,1,0,0,0,0,0,16#1C1#,valid,0 ns);
                    command_seq(61):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- The OTP Program command can be issued multiple times to
                    -- any given OTP address, but this address space can never
                    -- be erase
                    command_seq(62):=(w_enable,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(otp_prog,none     ,1,0,0,0,16#FC#,0,16#310#,valid,0 ns);
                    command_seq(65):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(read_SR1  ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(wt      ,none     ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(69):=(read_SR1  ,rd_wip_0 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(read_SR1  ,pgm_succ ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(otp_read,read_otp ,1,0,0,0,0,0,16#310#,valid,0 ns);
                    command_seq(73):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(74):=(w_enable,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(otp_prog,none     ,1,0,0,0,16#3C#,0,16#310#,valid,0 ns);
                    command_seq(77):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(read_SR1  ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(wt      ,none     ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(81):=(read_SR1  ,rd_wip_0 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(read_SR1  ,pgm_succ ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(otp_read,read_otp ,1,0,0,0,0,0,16#310#,valid,0 ns);
                    command_seq(85):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that previously programmed value is not changed
                    command_seq(86):=(w_enable,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(otp_prog,none     ,1,0,0,0,16#3F#,0,16#310#,valid,0 ns);
                    command_seq(89):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(read_SR1  ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(wt      ,none     ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(93):=(read_SR1  ,rd_wip_0 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(94):=(read_SR1  ,pgm_succ ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(otp_read,read_otp ,1,0,0,0,0,0,16#310#,valid,0 ns);
                    command_seq(97):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(98):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN 2  =>
                    REPORT "OTP program positive test";
                    --OTP Page Programming
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(otp_prog,none ,200,0,0,0,16#01#,0,16#200#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register1 during OTP Page Program operation
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register during OTP Page Program operation
                    command_seq(8) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register During OTP Page Program Operation
                    command_seq(10):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(11):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read command is not allowed during OTP Program
                    command_seq(12):=(rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(15):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(otp_read ,read_otp ,10,0,0,0,0,0,16#200#,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "OTP program positive test, QPI";
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns); 
                    --OTP Page Programming
                    command_seq(10) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(otp_prog,none ,10,0,0,0,16#FA#,0,16#060#,valid,0 ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register1 during OTP Page Program operation
                    command_seq(14) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register during OTP Page Program operation
                    command_seq(17) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register During OTP Page Program Operation
                    command_seq(19):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(20):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read command is not allowed during OTP Program
                    command_seq(21):=(fast_rd4,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(24):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(otp_read ,read_otp ,10,0,0,0,0,0,16#060#,valid,0 ns);
                    command_seq(30) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33) :=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(34) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(38):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 16  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "OTP program negative test";
                    -- programming locked region
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(otp_prog,err  ,1,0,0,0,16#99#,0,16#0A1#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(9) :=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_disable,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>--programming over address limit in OTP
                    REPORT "OTP program negative test";
                    --OTP Program operations outside the valid OTP Range will be
                    --ignored without P_ERR set to '1'
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --programmed bytes will cross over 1024 byte limit
                    command_seq(4) :=(otp_prog,none ,5,0,0,0,16#DD#,0,16#3FD#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(clr_sr ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --address is out of range
                    command_seq(10) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(otp_prog,err,1,0,0,0,16#DD#,0,16#400#,valid,0 ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>--programming 16 lowest address bytes
                    REPORT "OTP program negative test";
                    --Programming zeros at 16 lowest address bytes will fail and
                    --set P_ERR
                    command_seq(1) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(otp_prog ,err       ,1,0,0,0,16#DD#,0,16#05#,valid,0 ns);
                    command_seq(5) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1   ,rd_wip_1  ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(read_SR1   ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(9) :=(clr_sr   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_disable,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    --Programming ones at 16 lowest address bytes is ignored
                    --without P_ERR set to "1"
                    command_seq(12):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(w_enable ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(otp_prog ,err       ,1,0,0,0,16#FF#,0,16#05#,valid,0 ns);
                    command_seq(16):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(read_SR1   ,rd_wip_0  ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1   ,pgm_succ  ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(otp_read ,read_otp  ,10,0,0,0,0,0,16#05#,valid,0 ns);
                    command_seq(21):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(done    ,none      ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 17 => -- page program positive test
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "Page program positive test (3 bytes address)";
                    --Page Size = 256 Bytes
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog,none  ,1,0,0,0,16#BF#,7,16#A#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rd     ,read  ,1,0,0,0,0,7,16#A#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(pg_prog,none  ,3,0,0,0,16#AB#,4,16#11#,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(21):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rd     ,read  ,3,0,0,0,0,4,16#11#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(pg_prog,none  ,260,0,0,0,16#AA#,14,16#CB#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR1V during Page Program
                    command_seq(30):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR2V during Page Program
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register during Page Program
                    command_seq(34):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(35):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR1V during Page Program
                    command_seq(36):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read command is not allowed during Page Program
                    command_seq(38):=(rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --WREN command is not allowed during Page Program
                    command_seq(40):=(w_enable,err    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(43):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle     ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Page Program Command is issued on the previously programmed
                    -- Location
                    command_seq(48):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(pg_prog,none  ,1,0,0,0,16#BA#,7,16#A#,valid,0 ns);
                    command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(55):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(rd     ,read  ,1,0,0,0,0,7,16#A#,valid,0 ns);
                    command_seq(59):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Page program positive test (3 bytes address)";
                    --Page Size = 512 Bytes
                    command_seq(0) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(1) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V(4) is set to '1'
                    command_seq(3) :=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800004#,valid,0 ns);
                    command_seq(4) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(6) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Page Program Operation is initiatied
                    command_seq(7) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(pg_prog,none  ,520,0,0,0,16#01#,9,0,valid,0 ns);
                    command_seq(10):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(14):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(rd     ,read  ,10,0,0,0,0,9,0,valid,0 ns);
                    command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(rd     ,read  ,10,0,0,0,0,9,502,valid,0 ns);
                    command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "Page program positive test (4 bytes address)";
                    --Page Size = 512 Bytes
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,1,0,0,0,16#77#,16,16#A#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rd_4     ,read_4,1,0,0,0,0,16,16#A#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(pg_prog4,none ,3,0,0,0,16#AB#,17,16#11#,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512); 
                    command_seq(21):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rd_4     ,read_4,3,0,0,0,0,17,16#11#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(pg_prog4,none ,520,0,0,0,16#AB#,18,16#CC#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512); 
                    command_seq(37):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(rd     ,read  ,6,0,0,0,0,18,16#CC#,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 4  =>
                    REPORT "Page program positive test (Quad All Mode)";
                    --Page Size = 512 Bytes
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Set QUAD bit to '1'
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#02#,0,16#00800002#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Page Program Operation is initiatied (3 Bytes Address)
                    command_seq(10):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(pg_prog,none ,16,0,0,0,16#A0#,19,16#10#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(19):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(quad_high_rd,read_quad_hi,16,0,0,0,0,19,16#10#,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Page Program Operation is initiatied (4 Bytes Address)
                    command_seq(24):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(pg_prog4,none ,16,0,0,0,16#B0#,19,16#20#,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512); 
                    command_seq(33):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(quad_high_rd,read_quad_hi,16,0,0,0,0,19,16#20#,valid,0 ns);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 5  =>
                    REPORT "QUAD Page program positive test (Quad All Mode)";
                    -- Erase sector before QUAD PP
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none ,16,0,0,0,16#01#,32,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(pg_prog4,none ,16,0,0,0,16#01#,32,16#3FF0#,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(19):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(quad_high_rd   ,read_quad_hi,10,0,0,0,0,32,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(quad_high_rd   ,read_quad_hi,10,0,0,0,0,32,16#3FF0#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(sector_erase,none,0,0,0,0,0,64,0,valid,0 ns);
                    command_seq(29):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);

                    command_seq(30) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --CR3V(4) is set to '1'
                    command_seq(32) :=(wrar  ,none      ,1,0,0,0,16#10#,0,16#00800004#,valid,0 ns);
                    command_seq(33) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(35) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Page Program Operation is initiatied
                    command_seq(36) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Set QUAD bit to '0'
--                     command_seq(39) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(40) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(41) :=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800002#,valid,0 ns);
--                     command_seq(42) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(43) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(44) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(45) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
--                     command_seq(46) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(47):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 6  =>
                    REPORT "Enter QPI";
                    --enter opi
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4):=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(7) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    -- Disabling bit walking
                    command_seq(11) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800005#,valid,0 ns);
                    command_seq(15) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(17) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- Set QUAD bit to '1'
--                     command_seq(19) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(20) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(21) :=(wrar  ,none      ,1,0,0,0,16#02#,0,16#00800002#,valid,0 ns);
--                     command_seq(22) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(23) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
--                     command_seq(24) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(25) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
--                     command_seq(26) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(27):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN 7  =>
                    REPORT "Bit-walking positive test(4 bytes address)";
                    --Page Size = 512 Bytes
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,520,0,0,0,16#77#,58,16#80#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(9) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(quad_high_rd   ,read_quad_hi,5,0,0,0,0,58,16#80#,valid,0 ns);
--                     command_seq(12):=(rd_4    ,read_4,1,0,0,0,0,16,16#A#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(pg_prog4,none ,16,0,0,0,16#AA#,58,16#1F0#,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(21):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(quad_high_rd   ,read_quad_hi,5,0,0,0,0,58,16#1F0#,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    --                     command_seq(24):=(rd_4     ,read_4,3,0,0,0,0,17,16#11#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(pg_prog4,none ,5,0,0,0,16#AB#,58,16#CC#,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(41):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(quad_high_rd   ,read_quad_hi,6,0,0,0,0,58,16#CC#,valid,0 ns);
--                     command_seq(40):=(rd_4   ,read_4,6,0,0,0,0,18,16#CC#,valid,0 ns);
                    command_seq(49):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    WHEN 8  =>
                    REPORT "Bit-walking negative test(4 bytes address)";
                    --Page Size = 512 Bytes
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,263,0,0,0,16#77#,59,16#10#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(9) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(quad_high_rd   ,read_quad_hi,5,0,0,0,0,59,16#10#,valid,0 ns);
--                     command_seq(12):=(rd_4    ,read_4,1,0,0,0,0,16,16#A#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(pg_prog4,none ,5,0,0,0,16#AA#,59,16#05#,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(21):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(quad_high_rd   ,read_quad_hi,5,0,0,0,0,59,16#05#,valid,0 ns);
--                     command_seq(24):=(rd_4     ,read_4,3,0,0,0,0,17,16#11#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(pg_prog4,none ,5,0,0,0,16#AB#,59,16#120#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(37):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(quad_high_rd   ,read_quad_hi,5,0,0,0,0,59,16#120#,valid,0 ns);
--                     command_seq(40):=(rd_4   ,read_4,6,0,0,0,0,18,16#CC#,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN 9  =>
                    REPORT "EXIT QPI";
                    --exit opi
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(5):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800003#,valid,0 ns);
                    -- exit QUAD_IT
                    command_seq(11) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wrar  ,none      ,1,0,0,0,16#20#,0,16#00800002#,valid,0 ns);
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(17) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800002#,valid,0 ns);
                    -- Disabling bit walking
                    command_seq(21) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24) :=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800005#,valid,0 ns);
                    command_seq(25) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(27) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28) :=(done   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN 10  =>
                    REPORT "SPI bit walking test neg/pos (4 bytes address)";
                    --Page Size = 512 Bytes

                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,520,0,0,0,16#88#,98,16#1A#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(11) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(rd_4   ,read_4,1,0,0,0,0,98,16#1A#,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(pg_prog4,none ,3,0,0,0,16#AB#,98,16#200#,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(23):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(rd_4     ,read_4,3,0,0,0,0,98,16#1A#,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(pg_prog4,none ,5,0,0,0,16#AB#,98,16#00#,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(39):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(rd_4   ,read_4,6,0,0,0,0,98,16#1A#,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enabling bit walking
                    command_seq(48) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51) :=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800005#,valid,0 ns);
                    command_seq(52) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(54) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                     -- enter QUAD_IT
                    command_seq(55) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(wrar  ,none      ,1,0,0,0,16#22#,0,16#00800002#,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(61) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(64) :=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    WHEN OTHERS => NULL;
                END CASE;

           WHEN 18  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "Program suspend, positive test";
                    -- Quad All Mode Active
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none   ,520,0,0,0,16#99#,60,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --When the Program Suspend command is written during a
                    --program operation, the device requires a maximum
                    --of tPGSUSP to suspend the program operation.
                    command_seq(8) :=(prg_susp_b0,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                    command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(rdar_read ,rd_ps_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    --Read Array during Program Suspend
                    ------------------------------------------------------------
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        command_seq(14):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(14):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    --Read Array from Program Suspended sector
                    command_seq(18):=(quad_high_rd_4,rd_U,2,0,0,0,0,60,5,valid,0 ns);
                    command_seq(19):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none    ,0,0,0,0,0,0,0,valid,10 ns);
                    --Read Array from Program Suspended sector
                    command_seq(21):=(quad_high_ddr_rd_4,rd_U,2,0,0,0,0,60,5,valid,0 ns);
                    command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(wt     ,none    ,0,0,0,0,0,0,0,valid,10 ns);
                    --DYB Access Register Read command is not allowed during Program Suspend
                    command_seq(24):=(dybacc_rd4,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --The system must write the Program Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(26):=(prg_resume_7a,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Program Resume to next Program Suspend
                    --Typical period of 100 us is needed for Program to progress
                    --to completion. If PGSP command is issued during tPRS time
                    --warning is generated
                    command_seq(29):=(prg_susp_75,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEPS);
                    --Verify that PRSP command is rejected
                    command_seq(32):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(rdar_read ,rd_ps_0 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(34):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tRS);
                    --New PGSUSP command is issued
                    command_seq(36):=(prg_susp_75,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEPS);
                    --Verify that PRSP command is accepted
                    command_seq(39):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(rdar_read ,rd_ps_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --The system must write the Program Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(42):=(prg_resume_8a,none ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(45):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(quad_high_rd_4,read_quad_hi4 ,10,0,0,0,0,60,0,valid,0 ns);
                    command_seq(49):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Set QA bit to '0'
                    command_seq(50):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(53):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(55):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Program suspend, positive test";
                    -- QA = '0'
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none   ,50,0,0,0,16#A0#,60,16#400#,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --When the Program Suspend command is written during a
                    --program operation, the device requires a maximum
                    --of tPGSUSP to suspend the program operation.
                    command_seq(8) :=(prg_susp_85,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                    -- Read SR1V during Program Suspend
                    command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR2V during Program Suspend
                    command_seq(13):=(rdar_read ,rd_ps_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(14):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR1V during Program Suspend
                    command_seq(15):=(read_SR2 ,rd_SR2,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    --Read Array during Program Suspend
                    ------------------------------------------------------------
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        --Read Array during Program Suspend - NORMAL READ
                        command_seq(17):=(rd_4      ,read_4   ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(18):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(fast_rd4  ,read_fast_4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(20):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(22):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(24):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(25):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(26):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(17):=(rd_4     ,read_4  ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(fast_rd4,read_fast_4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(25):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(26):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    --Read Array from Program Suspended page
                    command_seq(27):=(rd              ,rd_U    ,2,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(28):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(fast_rd         ,rd_U    ,2,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(30):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(dual_high_rd    ,rd_U    ,2,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(32):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(quad_high_rd    ,rd_U    ,2,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(34):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(quad_high_ddr_rd,rd_U    ,2,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(36):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- dual high performance read - Initial access, mode bits are Axh
                    command_seq(37):=(dual_high_rd,read_dual_hi,5,0,0,0,16#A0#,0,0,valid,0 ns);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous dual high performance read - Subsequent access
                    command_seq(39):=(dual_high_rd,rd_cont_dualIO,5,0,0,0,16#A0#,1,1,break,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Initiate MBR command to release from Continuous Read
                    command_seq(41):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Reset Enable Command followed by command other than RST
                    command_seq(43):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(w_disable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Clear Status Register Command
                    command_seq(47):=(clr_sr   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    --The system must write the Program Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(49):=(prg_resume_7a,none ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(50):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(52):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(fast_rd4,read_fast_4,5,0,0,0,0,60,16#400#,valid,0 ns);
                    command_seq(56):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dummy
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Activate Burst Wrap Model and set Wrap Length to 16
                    command_seq(63):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(wrar  ,none      ,1,0,0,0,16#00#,0,16#00800010#,valid,0 ns);
                    command_seq(66):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(68):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Dummy
                    command_seq(69):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that Wrap Length is set to 16 (CR4V(1:0))
                    command_seq(71):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800005#,valid,0 ns);
                    command_seq(72):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- New Program Operation is issued
                    command_seq(73):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(pg_prog4,none   ,50,0,0,0,16#A0#,60,16#600#,valid,0 ns);
                    command_seq(76):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --When the Program Suspend command is written during a
                    --program operation, the device requires a maximum
                    --of tPGSUSP to suspend the program operation.
                    command_seq(79):=(prg_susp_75,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(81):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                    -- Read SR1V during Program Suspend
                    command_seq(82):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR2V during Program Suspend
                    command_seq(84):=(rdar_read ,rd_ps_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(85):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Fast Read
                    command_seq(86):=(fast_rd4,read_fast_4,10,0,0,0,0,1,14,valid,0 ns);
                    command_seq(87):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Dual I/O High Performance Read Mode
                    command_seq(88):=(dual_high_rd_4,read_dual_hi4,10,0,0,0,0,1,14,valid,0 ns);
                    command_seq(89):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O High Performance Read Mode
                    command_seq(90):=(quad_high_rd_4,read_quad_hi4,10,0,0,0,0,1,14,valid,0 ns);
                    command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Quad I/O DDR Read Mode
                    command_seq(92):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,10,0,0,0,0,1,14,valid,0 ns);
                    command_seq(93):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --The system must write the Program Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(94):=(prg_resume_8a,none ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(95):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(97):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(99):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(fast_rd4,read_fast_4,5,0,0,0,0,60,16#600#,valid,0 ns);
                    command_seq(101):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

           WHEN 19  =>
                REPORT "Program Password Register, positive test";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_password,none ,1,16#99#,0,16#99#,16#3C#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register During Program Password Register Operation
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during Program Password Register
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000020#,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

           WHEN 20  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "PPB Program, positive test";
                    --PPB bits can be changed if PPB LOCK = '1';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_ppb  ,none    ,1,0,0,0,0,15,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register During Program PPB Program Operation
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PPB Program Operation
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbacc_rd,read_ppbar,2,0,0,0,0,15,19,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "PPB Program, negative test";
                    --PPB bits can't be changed if PPB LOCK = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --The PLBWR command is initiated to clear PPBLOCk bit to "0"
                    command_seq(4) :=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PLBWR Operation
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(w_ppb  ,none    ,1,0,0,0,0,17,0,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(29):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(34):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enable Hardware Reset
                    command_seq(35):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(wrar  ,none      ,1,0,0,0,16#28#,0,16#00000003#,valid,0 ns);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000003#,valid,0 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- reset device
                    command_seq(43):=(h_io3_reset,none     ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(44):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tRH);
                    -- confirm PPB Lock bit is set
                    command_seq(46) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

           WHEN 21  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "PPB ERASE, negative test";
                    --PPB bits can't be changed if PPB LOCK = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --The PLBWR command is initiated to clear PPBLOCk bit to "0"
                    command_seq(4) :=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(14):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(ppb_ers,err    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When E_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(18):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(read_SR1 ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- reset device
                    command_seq(21):=(h_reset,none     ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tRH);
                    -- confirm PPB Lock bit is set
                    command_seq(24) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(ppbacc_rd,read_ppbar,2,0,0,0,0,15,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "PPB ERASE, positive test";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppb_ers,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PPBE Operation
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbacc_rd,rd_ppblock_1,2,0,0,0,0,15,19,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "PPB ERASE, negative test";
                    --PPB Erase command is disabled if PPBOTP = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_ppb  ,none    ,1,0,0,0,0,40,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(ppbacc_rd,read_ppbar,2,0,0,0,0,40,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Setting up PPBOTP bit to '0'
                    command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(wrar  ,none     ,1,0,0,0,16#F7#,0,16#30#,valid,0 ns);
                    command_seq(20):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(25):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --PPB Erase command is issued
                    command_seq(30):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(ppb_ers,err    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that command is rejected
                    command_seq(34):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that E_ERR bit is set to '1'
                    command_seq(36):=(read_SR1  ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(38):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(ppbacc_rd,read_ppbar,2,0,0,0,0,40,0,valid,0 ns);
                    command_seq(43):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

           WHEN 22  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "DYB Program, positive test";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_dyb4  ,none    ,1,0,0,0,0,15,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(dybacc_rd4,read_dybar_4,2,0,0,0,0,15,19,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --DYB[15] = '0' => Sector 15 is protected
                    command_seq(16):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(pg_prog4,none  ,1,0,0,0,16#AA#,15,19,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(23):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Setting up DYB[15] to '1'
                    command_seq(27):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(w_dyb  ,none    ,1,0,0,0,16#FF#,15,0,valid,0 ns);
                    command_seq(30):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(31):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(33):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(35):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(37):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(38):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during DYBWR Operation
                    command_seq(39):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(42):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(dybacc_rd,read_dybar,2,0,0,0,0,15,19,valid,0 ns);
                    command_seq(46):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(49):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(52):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(54):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --DYB[26] = '0' => Sector 26 is protected
                    command_seq(55):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(w_dyb4  ,none    ,1,0,0,0,0,26,0,valid,0 ns);
                    command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(62):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(dybacc_rd4,read_dybar_4,2,0,0,0,0,26,19,valid,0 ns);
                    command_seq(66):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    --Setting up DYB[26] to '1'
                    command_seq(67):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(69):=(w_dyb  ,none    ,1,0,0,0,16#FF#,26,0,valid,0 ns);
                    command_seq(70):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(71):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(73):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(75):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(77):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(78):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during DYBWR Operation
                    command_seq(79):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(81):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(82):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(85):=(dybacc_rd,read_dybar,2,0,0,0,0,26,19,valid,0 ns);
                    command_seq(86):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Set QA bit to '0'
                    command_seq(87):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(89):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(90):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(92):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(93):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(94):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 23  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "Program ASP Register, Illegal condition";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                     --PWDMLB='0' & PSTMLB='0'
                    command_seq(4) :=(w_asp  ,none    ,1,0,0,0,16#FFF1#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(9):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(13):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                     --PWDMLB='0' & PSTMLB='0'
                    command_seq(15):=(wrar  ,none    ,1,0,0,0,16#FFF1#,0,16#30#,valid,0 ns);
                    command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1  ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(20):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Program ASP Register test";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --PPBOTP bit is OTP, it can't be programmed more than once
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_asp  ,none    ,1,0,0,0,16#FFFF#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(7) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(9) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during ASP Register Program
                    command_seq(11):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(14):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    --PPBOTP bit is OTP, it can't be programmed more than once
                    command_seq(19):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(wrar  ,none    ,1,0,0,0,16#FF#,0,16#30#,valid,0 ns);
                    command_seq(22):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(24):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(26):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during ASP Register Program
                    command_seq(28):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(31):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                     --An attempt is made to change the value of RFU bits
                    command_seq(36):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wrar   ,none    ,1,0,0,0,16#F0#,0,16#31#,valid,0 ns);
                    command_seq(39):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(43):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 24  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "SECTOR ERASE: positive test (256KB)";
                    -- 3 Bytes address and EXTADD = '0'
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,10,0,0,0,16#01#,64,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(pg_prog4,none  ,16,0,0,0,16#01#,64,16#3FFF0#,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(19):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(rd_4     ,read_4,10,0,0,0,0,64,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rd_4     ,read_4,10,0,0,0,0,64,16#3FFF0#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(sector_erase,none,0,0,0,0,0,64,0,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(30):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(34):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(36):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(37):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Sector Erase
                    command_seq(38):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(41):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(rd_4     ,read_4,10,0,0,0,0,64,16#3FFF0#,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- 4 Bytes address
                    command_seq(46):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(pg_prog4,none  ,10,0,0,0,16#01#,75,0,valid,0 ns);
                    command_seq(49):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(53):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(pg_prog4,none  ,16,0,0,0,16#01#,75,16#3FFF0#,valid,0 ns);
                    command_seq(59):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(63):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(65):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(rd_4     ,read_4,10,0,0,0,0,35,0,valid,0 ns);
                    command_seq(67):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(rd_4     ,read_4,10,0,0,0,0,35,16#3FFF0#,valid,0 ns);
                    command_seq(69):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(sector_erase_4,none,0,0,0,0,0,35,0,valid,0 ns);
                    command_seq(73):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(74):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(76):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(78):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(80):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(81):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Sector Erase
                    command_seq(82):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(85):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(88):=(ees    ,chk_sts_1  ,0,0,0,0,0,35,0,valid,0 ns);
                    command_seq(89):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(90):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tEES);
                    command_seq(91):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(94):=(rd_4     ,read_4,10,0,0,0,0,35,16#3FFF0#,valid,0 ns);
                    command_seq(95):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "Sector Erase applied to a 256 KB range that includes"&
                           "4 KB sectors";
                    IF Sec_Arch = FALSE THEN
                        command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(4) :=(sector_erase_4,none,0,0,0,0,0,532,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(10):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                        command_seq(11):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(14):=(rd_4   ,read_4,5,0,0,0,0,532,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(rd_4   ,read_4,5,0,0,0,0,533,0,valid,0 ns);
                        command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(rd_4   ,read_4,5,0,0,0,0,534,0,valid,0 ns);
                        command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Sector 255 is erased
                        command_seq(20):=(rd_4   ,read_4,5,0,0,0,0,511,0,valid,0 ns);
                        command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(rd_4   ,read_4,5,0,0,0,0,511,16#7FF0#,valid,0 ns);
                        command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(4) :=(sector_erase_4,none,0,0,0,0,0,22,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(10):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                        command_seq(11):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(14):=(rd_4   ,read_4,5,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(rd_4   ,read_4,5,0,0,0,0,1,0,valid,0 ns);
                        command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(rd_4   ,read_4,5,0,0,0,0,7,0,valid,0 ns);
                        command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Sector 32 is erased
                        command_seq(20):=(rd_4   ,read_4,5,0,0,0,0,32,0,valid,0 ns);
                        command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(rd_4   ,read_4,5,0,0,0,0,32,16#7FF0#,valid,0 ns);
                        command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    WHEN 3  =>
                    REPORT "Parameter 4 KB-sector Erase: positive test";
                    IF Sec_Arch = FALSE THEN
                        command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(4) :=(p4_erase_4,none,0,0,0,0,0,256,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 1
                        command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 2
                        command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Configuration Register
                        command_seq(10):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        -- Read Any Register
                        command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                        command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                        --Fast Read command is not allowed during Sector Erase
                        command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE4);
                        command_seq(17):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(20):=(rd_4   ,read_4,5,0,0,0,0,256,0,valid,0 ns);
                        command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(4) :=(p4_erase,none,0,0,0,0,0,7,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 1
                        command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 2
                        command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Configuration Register
                        command_seq(10):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        -- Read Any Register
                        command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                        command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                        --Fast Read command is not allowed during Sector Erase
                        command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE4);
                        command_seq(17):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(20):=(rd   ,read,5,0,0,0,0,7,0,valid,0 ns);
                        command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(22):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wrar  ,none      ,1,0,0,0,16#02#,0,16#00800002#,valid,0 ns);
                    command_seq(25):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(28):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(30):=(p4_erase_4,none,0,0,0,0,0,262,0,valid,0 ns);
                        command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 1
                        command_seq(32):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- Read Any Register
                        command_seq(34):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                        command_seq(35):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                        --Fast Read command is not allowed during Sector Erase
                        command_seq(36):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE4);
                        command_seq(39):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(40):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(42):=(quad_high_rd_4,read_quad_hi4,10,0,0,0,0,262,0,valid,0 ns);
                        command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(28):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Sector Erase command is applied to a 256 KB range that includes
                        --4 KB sectors
                        command_seq(30):=(p4_erase,none,0,0,0,0,0,1,0,valid,0 ns);
                        command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --Read Status Register 1
                        command_seq(32):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- Read Any Register
                        command_seq(34):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                        command_seq(35):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                        --Fast Read command is not allowed during Sector Erase
                        command_seq(36):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                        command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE4);
                        command_seq(39):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(40):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        --Verify that Parameter Sectors from selected 256KB region
                        --are not erased
                        command_seq(42):=(quad_high_rd_4,read_quad_hi4,10,0,0,0,0,1,0,valid,0 ns);
                        command_seq(43):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    -- Set QA bit to '0'
                    command_seq(44):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00800003#,valid,0 ns);
                    command_seq(47):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(49):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(51):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 25  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "SECTOR ERASE: negative test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(sector_erase,err,0,0,0,0,0,40,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(read_SR1  ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(9) :=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 26  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "ERASE SUSPEND: positive test";
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(sector_erase,none,0,0,0,0,0,35,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --When the Erase Suspend command is written during a
                    --erase operation, the device requires a maximum
                    --of tESL to suspend the erase operation.
                    command_seq(8) :=(ers_susp_b0,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                    -- Read SR1V during Erase Suspend
                    command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read SR2V during Erase Suspend
                    command_seq(13):=(rdar_read ,rd_es_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(14):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read CR1V during Erase Suspend
                    command_seq(15):=(read_SR2 ,rd_SR2,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    ------------------------------------------------------------
                    --Read Array during Erase Suspend
                    ------------------------------------------------------------
                    -- Reading from the top of memory array (verify that when the
                    -- highest address is reached, the address counter will wrap
                    -- around and roll back to 0000000h, allowing the read sequence
                    -- to be continued indefinitely.
                    IF Sec_Arch = FALSE THEN
                        --Read Array during Erase Suspend - NORMAL READ
                        command_seq(17):=(rd_4      ,read_4   ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(18):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(fast_rd4  ,read_fast_4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(20):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(22):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(24):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(25):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                        command_seq(26):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(17):=(rd_4     ,read_4  ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(fast_rd4,read_fast_4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(23):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(25):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                        command_seq(26):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    --Read Array from Erase Suspended Sector
                    command_seq(27):=(rd              ,rd_U    ,2,0,0,0,0,35,16#400#,valid,0 ns);
                    command_seq(28):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(fast_rd         ,rd_U    ,2,0,0,0,0,35,16#400#,valid,0 ns);
                    command_seq(30):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(dual_high_rd    ,rd_U    ,2,0,0,0,0,35,16#400#,valid,0 ns);
                    command_seq(32):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(quad_high_rd    ,rd_U    ,2,0,0,0,0,35,16#400#,valid,0 ns);
                    command_seq(34):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(quad_high_ddr_rd,rd_U    ,2,0,0,0,0,35,16#400#,valid,0 ns);
                    command_seq(36):=(idle            ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- dual high performance read - Initial access, mode bits are Axh
                    command_seq(37):=(dual_high_rd,read_dual_hi,5,0,0,0,16#A0#,0,0,valid,0 ns);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Continuous dual high performance read - Subsequent access
                    command_seq(39):=(dual_high_rd,rd_cont_dualIO,5,0,0,0,16#A0#,1,1,break,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Initiate MBR command to release from Continuous Read
                    command_seq(41):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    --Reset Enable Command followed by command other than RST
                    command_seq(43):=(reset_en,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(w_disable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle    ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Clear Status Register Command
                    command_seq(47):=(clr_sr   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    --The system must write the Erase Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(49):=(ers_resume_7a,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Erase Resume to next Erase Suspend
                    --Typical period of 100 us is needed for Program to progress
                    --to completion. If ESP command is issued during tEPR time
                    --warning is generated
                    command_seq(52):=(ers_susp_75,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEPS);
                    --Verify that EPR command is rejected
                    command_seq(55):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(rdar_read ,rd_es_0 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(57):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tRS);
                    --New EPS command is issued
                    command_seq(59):=(ers_susp_75,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEPS);
                    --Verify that EPS command is accepted
                    command_seq(62):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(rdar_read ,rd_es_1 ,1,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(64):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --The system must write the Erase Resume command
                    --to exit the program suspend mode and continue the
                    --program operation.
                    command_seq(65):=(ers_resume_8a,none ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(66):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(68):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(69):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 27  =>
                CASE Testcase IS
                    WHEN 1 =>
                    REPORT "PROGRAM DURING ERASE SUSPEND: positive test";
                        command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(4) :=(sector_erase,none,0,0,0,0,0,44,0,valid,0 ns);
                        command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        --When the Erase Suspend command is written during a
                        --erase operation, the device requires a maximum
                        --of tESL to suspend the erase operation.
                        command_seq(8) :=(ers_susp_b0,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(10):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                        command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(12):=(read_SR2 ,rd_es_1 ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        -- Program while erase is suspended
                        command_seq(14):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(16):=(pg_prog,none  ,10,0,0,0,16#AA#,19,0,valid,0 ns);
                        command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(18):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(19):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                        --When the Program Suspend command is written during a
                        --program operation, the device requires a maximum
                        --of tPGSUSP to suspend the program operation.
                        command_seq(20):=(prg_susp_b0,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(22):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEPS);
                        command_seq(23):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(24):=(read_SR2 ,rd_ps_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                        -- Reading from the top of memory array (verify that when the
                        -- highest address is reached, the address counter will wrap
                        -- around and roll back to 0000000h, allowing the read sequence
                        -- to be continued indefinitely.
                        IF Sec_Arch = FALSE THEN
                            --Read Array during Erase Suspend - NORMAL READ
                            command_seq(26):=(rd_4      ,read_4   ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                            command_seq(27):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(28):=(fast_rd4  ,read_fast_4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                            command_seq(29):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(30):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                            command_seq(31):=(idle      ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(32):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                            command_seq(33):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(34):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFE#,valid,0 ns);
                            command_seq(35):=(idle      ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        ELSE
                            command_seq(26):=(rd_4     ,read_4  ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                            command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(28):=(fast_rd4,read_fast_4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                            command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(30):=(dual_high_rd_4,read_dual_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                            command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(32):=(quad_high_rd_4,read_quad_hi4 ,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                            command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                            command_seq(34):=(quad_high_ddr_rd_4,read_ddr_quad_hi4,5,0,0,0,0,263,16#FFFE#,valid,0 ns);
                            command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        END IF;

                        --The system must write the Program Resume command
                        --to exit the program suspend mode and continue the
                        --sector erase suspend operation.
                        command_seq(36):=(prg_resume_7a,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(38):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(39):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                        command_seq(40):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(41):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(42):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(43):=(rd     ,read  ,3,0,0,0,16#AA#,19,0,valid,0 ns);
                        command_seq(44):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                        -- Program finished, erase will resume
                        command_seq(45):=(ers_resume_7a,none ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(46):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(47):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(48):=(wt     ,none    ,0,0,0,0,0,0,0,valid,tSE256);
                        command_seq(49):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(50):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(51):=(read_SR2 ,rd_es_0,1,0,0,0,0,0,0,valid,0 ns);
                        command_seq(52):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(53):=(rd     ,read    ,4,0,0,0,0,44,0,valid,0 ns);
                        command_seq(54):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(55):=(rd     ,read    ,4,0,0,0,0,44,16#AA#,valid,0 ns);
                        command_seq(56):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(57):=(rd     ,read    ,4,0,0,0,0,44,16#BFFE#,valid,0 ns);
                        command_seq(58):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(59):=(rd     ,read    ,4,0,0,0,0,44,16#3FFFE#,valid,0 ns);
                        command_seq(60):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                        command_seq(61):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 28  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "RESET DURING PAGE PROGRAM: positive test";
                    --Enable Software Reset Command
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#05#,0,16#00000004#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000004#,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(10):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(pg_prog,err  ,5,0,0,0,16#10#,38,16#01#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(19):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(rd     ,rd_U    ,1,0,0,0,0,38,16#01#,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "RESET DURING SECTOR ERASE: positive test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(sector_erase,err,0,0,0,0,0,45,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(11):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(rd     ,rd_U    ,1,0,0,0,0,45,0,valid,0 ns);
                    command_seq(14):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(15):=(ees    ,chk_sts_0  ,0,0,0,0,0,45,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tEES);
                    command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800001#,valid,0 ns);
                    command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(21):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "RESET DURING PROGRAM SUSPEND: positive test";
                    command_seq(1)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2)  :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4)  :=(pg_prog,err    ,50,0,0,0,16#99#,41,0,valid,0 ns);
                    command_seq(5)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6)  :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8)  :=(prg_susp_b0,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9)  :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10) :=(wt     ,none    ,0,0,0,0,0,0,0,valid,tEPS);
                    command_seq(11) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(read_SR2 ,rd_ps_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(17) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(idle   ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19) :=(rd     ,rd_U    ,5,0,0,0,0,41,16#10#,valid,0 ns);
                    command_seq(20) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21) :=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24) :=(done   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 29  =>
                CASE TestCase IS
                WHEN 1=>
                REPORT "BULK ERASE: negative test";
                --sectors are locked
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_sr  ,none      ,2,0,0,0,16#24#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(8) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(w_sr  ,none      ,1,0,0,0,16#14#,0,0,valid,0 ns);
                    command_seq(14):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(18):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(bulk_erase_60,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that E_ERR is not set
                    command_seq(26):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(rd     ,read  ,4,0,0,0,0,64,16#CC#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(32):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(w_sr  ,none      ,1,0,0,0,16#00#,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(37):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(40):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 2=>
                REPORT "BULK ERASE: positive test";
                    -- PPB Program command is issued
                    IF Sec_Arch = FALSE THEN
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_ppb  ,none    ,1,0,0,0,0,18,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(ppbacc_rd,read_ppbar,2,0,0,0,0,18,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- DYB Program command is issued
                    command_seq(14):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(w_dyb  ,none    ,1,0,0,0,0,60,0,valid,0 ns);
                    command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(21):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(dybacc_rd,read_dybar,2,0,0,0,0,60,19,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    --Bulk Erase command is issued
                    command_seq(26):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(bulk_erase_C7,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(34) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Bulk Erase
                    command_seq(36):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tBE);
                    command_seq(39):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that E_ERR is not set
                    command_seq(40):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(rd     ,read  ,10,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(rd     ,read  ,10,0,0,0,0,263,0,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that BE command skipped sectors protected by PPB and DYB bits
                    command_seq(46):=(rd     ,read  ,10,0,0,0,0,18,16#CC#,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(rd     ,read  ,10,0,0,0,0,60,0,valid,0 ns);
                    command_seq(49):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 30  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "WRITE STATUS negative test";
                    --Status Register can not be altered while SRWD = '1'
                    --and WP# = '0'
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar   ,none  ,1,0,0,0,16#80#,0,16#00800000#,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Verify that SRWD bit is set
                    command_seq(8) :=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    -- SRWD = '1', asserts WP# low
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(12):=(w_sr   ,none  ,1,0,0,0,16#7F#,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,violate,0 ns);
                    -- Verify that WEL = '0'
                    command_seq(14):=(read_SR1 ,rd_wel_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that WRR command is ignored
                    command_seq(16):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(18):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    -- SRWD = '1', asserts WP# low
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,violate,0 ns);
                    command_seq(20):=(wrar   ,none  ,1,0,0,0,16#7F#,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,violate,0 ns);
                    -- Verify that WEL = '0'
                    command_seq(22):=(read_SR1 ,rd_wel_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that WRAR command is ignored
                    command_seq(24):=(read_SR1 ,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(26):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>--FREEZE bit setting
                    REPORT "FREEZE bit, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --FREEZE bit set to 1
                    IF Sec_Arch = FALSE THEN
                        command_seq(6) :=(w_scr  ,none   ,2,0,0,0,16#822D#,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(6) :=(w_scr  ,none   ,2,0,0,0,16#8229#,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(8) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(10):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    --freeze bit cannot be cleared to 0 until a hardware-reset
                    command_seq(12):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(14):=(w_scr  ,none  ,0,0,0,0,16#2C#,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(14):=(w_scr  ,none  ,0,0,0,0,16#28#,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(16) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(18):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Configuration register didn't change its value
                    command_seq(19):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --freeze bit set to 1 locks the BP2-0 in Status Register
                    --BP0 = 1, BP1 = 1, BP2 = 0
                    command_seq(23):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(w_sr   ,none  ,1,0,0,0,16#0C#,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(read_SR1 ,none,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Hardware reset resets Freeze bit
                    command_seq(33):=(h_reset,none     ,0,0,0,0,0,0,0,valid,tRP);
                    command_seq(34):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(35):=(wt     ,none      ,0,0,0,0,0,0,0,valid,100 ns);
                    command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(read_CR1  ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>--FREEZE bit setting
                    REPORT "FREEZE bit, positive tests";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --FREEZE bit set to 1
                    IF Sec_Arch = FALSE THEN
                        command_seq(6) :=(w_scr  ,none   ,2,0,0,0,16#2D#,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(6) :=(w_scr  ,none   ,2,0,0,0,16#29#,0,0,valid,0 ns);
                        command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(8) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(10):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    --freeze bit cannot be cleared to 0 until a hardware-reset
                    command_seq(12):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    IF Sec_Arch = FALSE THEN
                        command_seq(14):=(w_scr  ,none  ,0,0,0,0,16#2C#,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(14):=(w_scr  ,none  ,0,0,0,0,16#28#,0,0,valid,0 ns);
                        command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(16) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(18):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Configuration register didn't change its value
                    command_seq(19):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --The configuration register FREEZE (CR1[0]) bit protects
                    --the entire OTP memory space from programming when set to “1”.
--                     command_seq(23):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(25):=(otp_read ,read_otp ,5,0,0,0,0,0,16#0B0#,valid,0 ns);
--                     command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(27):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(28):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(29):=(otp_prog,none ,5,0,0,0,16#AA#,0,16#0B0#,valid,0 ns);
--                     command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     --Verify that operation is rejected
--                     command_seq(31):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
--                     --Verify that P_ERR bit is set to '1'
--                     command_seq(32):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- A Clear Status Register followed by Write Disable command must
--                     -- be sent to return device to standby state
--                     command_seq(34):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(36):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(23):=(otp_read ,read_otp ,5,0,0,0,0,0,16#0B0#,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Software reset command does not affect Freeze bit
                    command_seq(25):=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(28):=(read_CR1  ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Hardware reset resets Freeze bit
                    command_seq(30):=(h_reset,none     ,0,0,0,0,0,0,0,valid,tRP);
                    command_seq(31):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(32):=(wt     ,none      ,0,0,0,0,0,0,0,valid,100 ns);
                    command_seq(33):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(read_CR1  ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                     WHEN 4  =>--LOCK bit setting
                     REPORT "LOCK bit, positive tests";
                         --cmd, sts, byte_num, data, sect, addr, aux_t, time
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --LOCK bit set to 1
                    IF Sec_Arch = FALSE THEN
                        command_seq(4):=(w_scr  ,none  ,0,0,0,0,16#3C#,0,0,valid,0 ns);
                        command_seq(5):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    ELSE
                        command_seq(4):=(w_scr  ,none  ,0,0,0,0,16#38#,0,0,valid,0 ns);
                        command_seq(5):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    END IF;
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(8) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    --LOCK bit is OTP, once set to 1 there isn't way to clear it
                    command_seq(10):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_scr  ,none  ,0,0,0,0,16#28#,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(16):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that Configuration register didn't change its value
                    command_seq(17):=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --LOCK bit set to 1 permanently locks the BP2-0 in the Status Register
                    command_seq(21):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(w_sr   ,none  ,1,0,0,0,16#18#,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read SR1NV
                    command_seq(28):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000000#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read SR1V
                    command_seq(30):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(32):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);


                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 31 => -- Persistent protection mode
                CASE TestCase IS
                WHEN 1 =>
                REPORT " Enter Persistent Protection mode-PPB Lock is set"&
                       " after reset";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enable Hardware Reset
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#28#,0,16#00000003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(7) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000003#,valid,0 ns);
                    command_seq(9) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(10):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                     -- enter Persistent Protection mode
                    command_seq(13):=(w_asp  ,none   ,1,0,0,0,16#FEDD#,0,0,valid,0 ns);
                    command_seq(14):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(21):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Setting up PPB Lock bit to value '0;
                    command_seq(25):=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(29):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(31) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(34):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- reset device
                    command_seq(41):=(h_reset,none   ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    -- confirm PPB Lock bit is set
                    command_seq(44) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(50):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(51):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    -- reset device
                    command_seq(51):=(h_reset,none   ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(52):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(54):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(55):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 32 =>
                CASE Testcase IS
                    WHEN 1 =>
                    REPORT "Deep power down mode positive test";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(dp_down,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(w_sr   ,none  ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tENTDPD);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,rd_HiZ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --resume from DP down without read electronic signature
                    command_seq(10):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(csneg_zero   ,none  ,0,0,0,0,0,0,0,valid,tCSDPD);
                    command_seq(12):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEXTDPD);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(read_SR1 ,err   ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enter to DPD
                    command_seq(16):=(dp_down,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tENTDPD);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Instructions are ignored during Power Down
                    command_seq(20):=(read_SR1 ,err   ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Write Instructions are ignored during Power Down
                    command_seq(22):=(w_enable,err  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --resume from DP down without read electronic signature
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(csneg_zero   ,none  ,0,0,0,0,0,0,0,valid,tCSDPD);
                    command_seq(26):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEXTDPD);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR1 ,err,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- QUAD ALL mode
                    -- Set QA bit to '1'
                    command_seq(30):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle    ,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(wrar    ,none ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enter to DPD
                    command_seq(34):=(dp_down,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tENTDPD);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Instructions are ignored during Power Down
                    command_seq(38):=(read_SR1 ,rd_HiZ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Write Instructions are ignored during Power Down
                    command_seq(40):=(w_enable,err  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --resume from DP down without read electronic signature
                    command_seq(42):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(csneg_zero   ,none  ,0,0,0,0,0,0,0,valid,tCSDPD);
                    command_seq(44):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tEXTDPD);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(read_SR1 ,err,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 33 => -- DIC ASO
            --cmd,sts,byte_num,data4,data3,data2,data1,sect,addr,aux_t,time
                CASE Testcase IS
                    WHEN 1 =>
                    REPORT "Positive, DIC ASO enter and read";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- DIC ASO is entered, Load Starting DIC address
                    command_seq(2) :=(w_dic  ,none  ,0,0,16#111#,0,16#165#,0,0,valid,0 ns);
                    -- read status register to check if device is busy
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    -- time needed for DIC calculation 
                    command_seq(5) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tDIC_SETUP);
                    command_seq(6) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- read status register to check if device is ready
                    command_seq(7) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- enter DIC read command
                    command_seq(9) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800095#,valid,0 ns);
                    command_seq(10) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800096#,valid,0 ns);
                    command_seq(12) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800097#,valid,0 ns);
                    command_seq(14) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800098#,valid,0 ns);
                    command_seq(16) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(done   ,none   ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2 =>
                    REPORT "Positive, DIC SUSPEND and read";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- DIC ASO is entered, Load Starting DIC address
                    command_seq(2) :=(w_dic  ,none  ,0,0,16#115#,0,16#135#,0,0,valid,0 ns);
                    -- read status register to check if device is busy
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    -- time needed for DIC calculation 
                    command_seq(5) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tDIC_SETUP);
                    command_seq(6) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    --When the DIC Suspend command is written during a
                    --DIC operation, the device requires a maximum
                    --of tDICSL to suspend the program operation.
                    command_seq(7):=(prg_susp_75,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tDICSL);
                    -- read status register to check if device is ready
                    command_seq(10) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- enter DIC read command
                    command_seq(12) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800095#,valid,0 ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800096#,valid,0 ns);
                    command_seq(15) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800097#,valid,0 ns);
                    command_seq(17) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00800098#,valid,0 ns);
                    command_seq(19) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Exit DIC
                    -- reset device
                    command_seq(20):=(h_reset,none   ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(21):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tRH);

                    command_seq(23):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none   ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 34 => -- password positive tests
                CASE Testcase IS
                WHEN 1 =>
                REPORT " POSITIVE Password program: program and verify " ;
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar   ,none    ,1,0,0,0,16#00#,0,16#20#,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wrar   ,none      ,1,0,0,0,16#01#,0,16#21#,valid,0 ns);
                    command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(19):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wrar   ,none      ,1,0,0,0,16#02#,0,16#22#,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(29):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(wrar   ,none      ,1,0,0,0,16#03#,0,16#23#,valid,0 ns);
                    command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(39):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wrar   ,none      ,1,0,0,0,16#04#,0,16#24#,valid,0 ns);
                    command_seq(45):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(49):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(wrar   ,none      ,1,0,0,0,16#05#,0,16#25#,valid,0 ns);
                    command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(59):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(wrar   ,none      ,1,0,0,0,16#06#,0,16#26#,valid,0 ns);
                    command_seq(65):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(69):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(wrar   ,none      ,1,0,0,0,16#07#,0,16#27#,valid,0 ns);
                    command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(79):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(81):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000021#,valid,0 ns);
                    command_seq(83):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Enable Hardware Reset
                    command_seq(84):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(85):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(wrar  ,none      ,1,0,0,0,16#28#,0,16#00000003#,valid,0 ns);
                    command_seq(87):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(89):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000003#,valid,0 ns);
                    command_seq(91):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 2 =>
                REPORT " Enter Password Protection mode- PPB Lock is cleared"&
                       " after reset";
                    command_seq(1):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- enter Password Protection mode
                    command_seq(6) :=(w_asp  ,none   ,1,0,0,0,16#FFFB#,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(10) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(14):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- reset device
                    command_seq(15):=(h_reset,none   ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(16):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(wt     ,none      ,0,0,0,0,0,0,0,valid,50 ms);
                    command_seq(18):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB Lock bit is cleared
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 3 =>
                REPORT "Password Unlock command sequence";
                    command_seq(1) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is cleared
                    command_seq(2) :=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,100 ns);
                    -- initiate password unlock sequence
                    command_seq(5) :=(idle,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(psw_unlock,none,0,16#0706#,16#0504#,16#0302#,16#0100#,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(10):=(read_SR2 ,rd_SR2,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(11) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(14):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is set
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Initiate PLBWR command to clear PPB Lock bit
                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(31):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB Lock bit is cleared
                    command_seq(34):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(38):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 35 => -- password negative tests
                CASE Testcase IS
                WHEN 1 =>
                REPORT " NEGATIVE Password read and program"&
                       " if Password protection set ";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_password,none ,1,0,0,0,16#FFFF#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(8) :=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- After the Password Protection Mode is selected,
                    -- the PASSRD command is ignored.
                    command_seq(12):=(rdar_read,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Password Register
                    command_seq(14):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(rdar_read,rd_U ,1,0,0,0,0,0,16#20#,valid,0 ns);
                    command_seq(16):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(rdar_read,rd_U ,1,0,0,0,0,0,16#21#,valid,0 ns);
                    command_seq(18):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(rdar_read,rd_U ,1,0,0,0,0,0,16#22#,valid,0 ns);
                    command_seq(20):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(rdar_read,rd_U ,1,0,0,0,0,0,16#23#,valid,0 ns);
                    command_seq(22):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(rdar_read,rd_U ,1,0,0,0,0,0,16#24#,valid,0 ns);
                    command_seq(24):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(rdar_read,rd_U ,1,0,0,0,0,0,16#25#,valid,0 ns);
                    command_seq(26):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(rdar_read,rd_U ,1,0,0,0,0,0,16#26#,valid,0 ns);
                    command_seq(28):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(rdar_read,rd_U ,1,0,0,0,0,0,16#27#,valid,0 ns);
                    command_seq(30):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 2 =>
                REPORT " NEGATIVE Password unlock: wrong password entered ";
                    command_seq(1) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is cleared
                    command_seq(2):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(3):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,100 ns);
                    -- initiate password unlock sequence
                    command_seq(7) :=(idle,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(psw_unlock,err,0,0,0,0,16#FFFF#,0,0,valid,0 ns);
                    command_seq(10) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
--                     --If the PASSU command supplied password does not match the hidden
--                     --password in the Password Register,an error is reported by setting
--                     --the P_ERR bit to 1. The WIP bit also remains set to 1.
--                     command_seq(13):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(14):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- A Clear Status Register followed by Write Disable command must
--                     -- be sent to return device to standby state
                    command_seq(15):=(h_reset   ,none  ,0,0,0,0,0,0,0,valid,250 ns);
--                     command_seq(13):=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(18):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(19):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(20):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- confirm PPB lock bit is still cleared
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPACC);
                    -- The model is ready to accept a new password command
                    command_seq(29):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;
                
            WHEN 36 => -- Read Sector Erase Count positive tests
                CASE Testcase IS
              WHEN 1 =>
                REPORT " Read Sector Erase Count positive tests";
                    -- 3 Bytes address and EXTADD = '0'
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(pg_prog4,none  ,10,0,0,0,16#01#,33,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(pg_prog4,none  ,16,0,0,0,16#01#,33,16#3FFF0#,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(19):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(rd_4     ,read_4,10,0,0,0,0,33,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(rd_4     ,read_4,10,0,0,0,0,33,16#3FFF0#,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(sector_erase_4,none,0,0,0,0,0,33,0,valid,0 ns);
                    command_seq(29):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(30):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(32):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(34):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800002#,valid,0 ns);
                    command_seq(35):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(36):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(37):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Sector Erase
                    command_seq(38):=(fast_rd4,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(41):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(read_SR1  ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(seerc_rd,none,0,0,0,0,0,33,0,valid,0 ns);
                    command_seq(45):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns); 
                    -- Read Sector Erase Register
                    command_seq(46):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSEERC);
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(49):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(51):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(53):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800091#,valid,0 ns);
                    command_seq(54):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --bulk erasse
                    command_seq(55):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(bulk_erase_C7,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(59):=(read_SR1 ,rd_wip_1 ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(61):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(63) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read command is not allowed during Bulk Erase
                    command_seq(65):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tBE);
                    command_seq(68):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    --Verify that E_ERR is not set
                    command_seq(69):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(rd     ,read  ,10,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(rd     ,read  ,10,0,0,0,0,263,0,valid,0 ns);
                    command_seq(74):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                     --Read Configuration Register
                    command_seq(75):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(seerc_rd,none,0,0,0,0,0,36,0,valid,0 ns);
                    command_seq(77):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns); 
                    -- Read Sector Erase Register
                    command_seq(78):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(79):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSEERC);
                    command_seq(80):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(81):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800091#,valid,0 ns);
                    command_seq(82):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    

                    command_seq(83):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    WHEN OTHERS => NULL;
                END CASE;
                
                WHEN 37 => -- JEDEC reset positive tests
                CASE Testcase IS
                WHEN 1 =>
                    REPORT "======================================================";
                    REPORT "JEDEC reset, positive test.";
                    REPORT "======================================================";
                    command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(jedec_reset,none    ,0,0,0,0,0,0,0,valid,500 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(done   ,none   ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;
                
                WHEN 38 => -- Autoboot Test
                CASE Testcase IS
                WHEN 1 =>
                    REPORT "======================================================";
                    REPORT "Autoboot reg write, QPI,  positive test.";
                    REPORT "======================================================";
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    command_seq(10) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000042#,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(w_enable,none    ,0,0,0,0,0,0,0,valid, ns);
                    command_seq(13) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(w_autoboot     ,none  ,0,0,0,16#0100#,16#0000#,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(19):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(22):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000042#,valid,0 ns);
                    command_seq(25) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26) :=(done   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
--                     
--                      REPORT "======================================================";
--                     REPORT "Autoboot reg write, SPI,  positive test.";
--                     REPORT "======================================================";
--                     command_seq(1) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(2) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000042#,valid,0 ns);
--                     command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(4) :=(w_enable,none    ,0,0,0,0,0,0,0,valid, ns);
--                     command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(6) :=(w_autoboot     ,none  ,0,0,0,16#0100#,0,0,0,valid,0 ns);
--                     command_seq(7):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(8):=(read_SR1  ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(9):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(10):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
--                     command_seq(11):=(read_SR1  ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(12):=(read_SR1  ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     --Read Status Register 2
--                     command_seq(14):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(16) :=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000042#,valid,0 ns);
--                     command_seq(17) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(18) :=(done   ,none   ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;
                
            WHEN 39  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "PPB Program, positive test, QPI";
                    --PPB bits can be changed if PPB LOCK = '1';
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns); 
                    command_seq(10) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns); 
                    command_seq(12):=(ppbacc_rd4,read_ppbar,1,0,0,0,0,0,16#40000#,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(w_ppb4  ,none    ,1,0,0,0,0,0,16#40000#,valid,0 ns);
                    command_seq(15) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(16) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(18) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(20) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register During Program PPB Program Operation
                    command_seq(22):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(23):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PPB Program Operation
                    command_seq(24):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(27):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(ppbacc_rd4,read_ppbar,1,0,0,0,0,0,16#40000#,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "PPB Program, negative test";
                    --PPB bits can't be changed if PPB LOCK = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --The PLBWR command is initiated to clear PPBLOCk bit to "0"
                    command_seq(4) :=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PLBWR Operation
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(w_ppb4  ,none    ,1,0,0,0,0,17,0,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- When P_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(read_SR1 ,pgm_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(29):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Enable Hardware Reset
                    command_seq(33):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(wrar  ,none      ,1,0,0,0,16#28#,0,16#00000003#,valid,0 ns);
                    command_seq(36):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000003#,valid,0 ns);
                    command_seq(40):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    -- reset device
                    command_seq(41):=(h_reset,none     ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(42):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tRH);
                    -- confirm PPB Lock bit is set
                    command_seq(44) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(49):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

           WHEN 40  =>
                CASE Testcase IS
                    WHEN 1  =>
                    REPORT "PPB ERASE, negative test, QPI";
                    --PPB bits can't be changed if PPB LOCK = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --The PLBWR command is initiated to clear PPBLOCk bit to "0"
                    command_seq(4) :=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(9) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    command_seq(14):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(ppb_ers,err    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- When E_ERR is set to to "1", the WIP bit will remain set to
                    -- one indicationg the device remains busy and unable to receive
                    -- most new operation commands.
                    command_seq(18):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(read_SR1 ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- reset device
                    command_seq(21):=(h_reset,none     ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(22):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tRH);
                    -- confirm PPB Lock bit is set
                    command_seq(24) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(ppbacc_rd,read_ppbar,2,0,0,0,0,15,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 2  =>
                    REPORT "PPB ERASE, positive test";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppb_ers,none    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 1
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(10) :=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Read Any Register
                    command_seq(12):=(rdar_read,rd_wip_1,1,0,0,0,0,0,16#00800000#,valid,0 ns);
                    command_seq(13):=(idle   ,none       ,0,0,0,0,0,0,0,valid,0 ns);
                    --Fast Read Command is not allowed during PPBE Operation
                    command_seq(14):=(fast_rd,rd_HiZ,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tSE256);
                    command_seq(17):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(read_SR1 ,erase_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbacc_rd,rd_ppblock_1,2,0,0,0,0,15,19,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN 3  =>
                    REPORT "PPB ERASE, negative test";
                    --PPB Erase command is disabled if PPBOTP = '0';
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_ppb4  ,none    ,1,0,0,0,0,40,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP512);
                    command_seq(11):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(ppbacc_rd,read_ppbar,2,0,0,0,0,40,0,valid,0 ns);
                    command_seq(15):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Setting up PPBOTP bit to '0'
                    command_seq(16):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(wrar  ,none     ,1,0,0,0,16#F7#,0,16#30#,valid,0 ns);
                    command_seq(20):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(25):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --PPB Erase command is issued
                    command_seq(30):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(ppb_ers,err    ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that command is rejected
                    command_seq(34):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Verify that E_ERR bit is set to '1'
                    command_seq(36):=(read_SR1  ,erase_nosucc,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(38):=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(ppbacc_rd,read_ppbar,2,0,0,0,0,40,0,valid,0 ns);
                    command_seq(43):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;
            WHEN 41 => -- password positive tests, QPI
                CASE Testcase IS
                WHEN 1 =>
                REPORT " POSITIVE Password program: program and verify, QPI " ;
                    command_seq(1) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(5) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(7):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(9):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    command_seq(10) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14) :=(wrar   ,none    ,1,0,0,0,16#00#,0,16#20#,valid,0 ns);
                    command_seq(15) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18) :=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(19) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(wrar   ,none      ,1,0,0,0,16#01#,0,16#21#,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(29):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(34):=(wrar   ,none      ,1,0,0,0,16#02#,0,16#22#,valid,0 ns);
                    command_seq(35):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(38):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(39):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(42):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(44):=(wrar   ,none      ,1,0,0,0,16#03#,0,16#23#,valid,0 ns);
                    command_seq(45):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(46):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(47):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(48):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(49):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(50):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(51):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54):=(wrar   ,none      ,1,0,0,0,16#04#,0,16#24#,valid,0 ns);
                    command_seq(55):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(57):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(59):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(60):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(61):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(62):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(63):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(64):=(wrar   ,none      ,1,0,0,0,16#05#,0,16#25#,valid,0 ns);
                    command_seq(65):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(66):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(67):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(68):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(69):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(70):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(71):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(72):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(73):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(74):=(wrar   ,none      ,1,0,0,0,16#06#,0,16#26#,valid,0 ns);
                    command_seq(75):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(76):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(77):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(78):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(79):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(80):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(81):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(82):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(83):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(84):=(wrar   ,none      ,1,0,0,0,16#07#,0,16#27#,valid,0 ns);
                    command_seq(85):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(86):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(87):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(88):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(89):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(90):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(91):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(92):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000021#,valid,0 ns);
                    command_seq(93):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    -- Enable Hardware Reset
                    command_seq(94):=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(95):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(96):=(wrar  ,none      ,1,0,0,0,16#08#,0,16#00000003#,valid,0 ns);
                    command_seq(97):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(98):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(99):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(100):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00000003#,valid,0 ns);
                    command_seq(101):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(102):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000020#,valid,0 ns);
                    command_seq(103):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(104):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000021#,valid,0 ns);
                    command_seq(105):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(106):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000022#,valid,0 ns);
                    command_seq(107):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(108):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000023#,valid,0 ns);
                    command_seq(109):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(110):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000024#,valid,0 ns);
                    command_seq(111):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(112):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000025#,valid,0 ns);
                    command_seq(113):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(114):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000026#,valid,0 ns);
                    command_seq(115):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(116):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000027#,valid,0 ns);
                    command_seq(117):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(118):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 2 =>
                REPORT " Enter Password Protection mode- PPB Lock is cleared"&
                       " after reset";
                    command_seq(1):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_enable,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- enter Password Protection mode
                    command_seq(6) :=(wrar  ,none   ,1,0,0,0,16#FB#,0,16#00000030#,valid,0 ns);
                    command_seq(7) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(10) :=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(rdar_read,read_rdar,1,0,0,0,0,0,16#00000030#,valid,0 ns);
                    command_seq(14):=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- reset device
                    command_seq(15):=(h_reset,none   ,0,0,0,0,0,0,0,valid,250 ns);
                    command_seq(16):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(wt     ,none      ,0,0,0,0,0,0,0,valid,50 ms);
                    command_seq(18) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(22) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(24):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(26):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    -- confirm PPB Lock bit is cleared
                    command_seq(27):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 3 =>
                REPORT "Password Unlock command sequence";
                    command_seq(1) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is cleared
                    command_seq(2) :=(ppbl_reg_rd,read_ppbl,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,100 ns);
                    -- initiate password unlock sequence
                    command_seq(5) :=(idle,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(psw_unlock,none,0,16#0706#,16#0504#,16#0302#,16#0100#,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Status Register 2
                    command_seq(10):=(read_SR2 ,rd_SR2,1,0,0,0,0,0,0,valid,0 ns);
                    --Read Configuration Register
                    command_seq(11) :=(read_CR1 ,rd_CR1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(14):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is set
                    command_seq(17):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(20):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(21):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- Initiate PLBWR command to clear PPB Lock bit
                    command_seq(22):=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(w_ppbl_reg,none ,1,0,0,0,16#F0#,0,0,valid,0 ns);
                    command_seq(25):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(26):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(read_SR2 ,rd_SR2,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(30):=(wt     ,none  ,0,0,0,0,0,0,0,valid,tPP256);
                    command_seq(31):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(read_SR1 ,pgm_succ,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(33):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB Lock bit is cleared
                    command_seq(34):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(35):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(36):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(37):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    
                    command_seq(38):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(39) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(40) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(41) :=(wrar  ,none      ,1,0,0,0,16#01#,0,16#00800004#,valid,0 ns);
                    command_seq(42) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(43):=(wt     ,none     ,0,0,0,0,0,0,0,valid,tW);
                    command_seq(44):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(45):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800004#,valid,0 ns);
                    command_seq(46):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns); 
                    command_seq(47):=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns); 
                    command_seq(48):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);  
                    command_seq(49):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(50):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(51) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(52) :=(w_enable,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(53) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(54) :=(wrar  ,none      ,1,0,0,0,16#48#,0,16#00800003#,valid,0 ns);
                    command_seq(55) :=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(56):=(wt     ,none     ,0,0,0,0,0,0,0,valid,50 ns);
                    command_seq(57):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(58):=(rdar_read,read_rdar,2,0,0,0,0,0,16#00800003#,valid,0 ns);
                    command_seq(59):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(60):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    
--                     command_seq(39):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN 42 => -- password negative tests
                CASE Testcase IS
                WHEN 1 =>
                REPORT " NEGATIVE Password read and program"&
                       " if Password protection set ";
                    command_seq(1) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(2) :=(w_enable,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(3) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(w_password,none ,1,0,0,0,16#FFFF#,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(7) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);

                    -- A Clear Status Register followed by Write Disable command must
                    -- be sent to return device to standby state
                    command_seq(8) :=(clr_sr ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(10):=(w_disable,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    -- After the Password Protection Mode is selected,
                    -- the PASSRD command is ignored.
                    command_seq(12):=(rdar_read,none,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    --Read Password Register
                    command_seq(14):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(15):=(rdar_read,rd_U ,1,0,0,0,0,0,16#20#,valid,0 ns);
                    command_seq(16):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(rdar_read,rd_U ,1,0,0,0,0,0,16#21#,valid,0 ns);
                    command_seq(18):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(19):=(rdar_read,rd_U ,1,0,0,0,0,0,16#22#,valid,0 ns);
                    command_seq(20):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(21):=(rdar_read,rd_U ,1,0,0,0,0,0,16#23#,valid,0 ns);
                    command_seq(22):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(rdar_read,rd_U ,1,0,0,0,0,0,16#24#,valid,0 ns);
                    command_seq(24):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(rdar_read,rd_U ,1,0,0,0,0,0,16#25#,valid,0 ns);
                    command_seq(26):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(rdar_read,rd_U ,1,0,0,0,0,0,16#26#,valid,0 ns);
                    command_seq(28):=(idle     ,none      ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(rdar_read,rd_U ,1,0,0,0,0,0,16#27#,valid,0 ns);
                    command_seq(30):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                WHEN 2 =>
                REPORT " NEGATIVE Password unlock: wrong password entered ";
                    command_seq(1) :=(idle   ,none   ,0,0,0,0,0,0,0,valid,0 ns);
                    -- confirm PPB lock bit is cleared
                    command_seq(2):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(3):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(4) :=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(5) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(6) :=(wt     ,none   ,0,0,0,0,0,0,0,valid,100 ns);
                    -- initiate password unlock sequence
                    command_seq(7) :=(idle,none ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(8) :=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(9) :=(psw_unlock,err,0,0,0,0,16#FFFF#,0,0,valid,0 ns);
                    command_seq(10) :=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(11) :=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(12):=(idle   ,none    ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(13):=(read_CR1 ,rd_CR1,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(14):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPP256);
--                     --If the PASSU command supplied password does not match the hidden
--                     --password in the Password Register,an error is reported by setting
--                     --the P_ERR bit to 1. The WIP bit also remains set to 1.
--                     command_seq(13):=(read_SR1 ,rd_wip_1,1,0,0,0,0,0,0,valid,0 ns);
--                     command_seq(14):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
--                     -- A Clear Status Register followed by Write Disable command must
--                     -- be sent to return device to standby state
                    command_seq(15):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(16):=(h_reset   ,none  ,0,0,0,0,0,0,0,valid,250 ns);
--                     command_seq(16):=(reset_cmd   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(17):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(18):=(wt     ,none      ,0,0,0,0,0,0,0,valid,tRH);
                    command_seq(19):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(20):=(w_enable   ,none     ,0,0,0,0,0,0,0,valid,0 ns);
                    
                    command_seq(21):=(idle   ,none     ,0,0,0,0,0,0,0,valid,0 ns);

                    -- confirm PPB lock bit is still cleared
                    command_seq(22):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(23):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,valid,0 ns);
                    command_seq(24):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(25):=(ppbl_reg_rd,read_ppbl,2,0,0,0,0,0,0,clock_num,0 ns);
                    command_seq(26):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(27):=(clr_sr  ,none,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(28):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(29):=(wt     ,none   ,0,0,0,0,0,0,0,valid,tPACC);
                    -- The model is ready to accept a new password command
                    command_seq(30):=(read_SR1 ,rd_wip_0,1,0,0,0,0,0,0,valid,0 ns);
                    command_seq(31):=(idle   ,none  ,0,0,0,0,0,0,0,valid,0 ns);
                    command_seq(32):=(done   ,none  ,0,0,0,0,0,0,0,valid,0 ns);

                    WHEN OTHERS => NULL;
                END CASE;

            WHEN OTHERS =>
        END CASE;

        REPORT "------------------------------------------------------";
    END PROCEDURE Generate_TC;

    ---------------------------------------------------------------------------
    --PUBLIC
    -- CHECKER PROCEDURES
    ---------------------------------------------------------------------------
----Check read from memory
    PROCEDURE   Check_read (
        DQ       :  IN std_logic_vector(7 downto 0);
        DQ_reg0  :  IN std_logic_vector(7 downto 0);
        DQ_reg1  :  IN std_logic_vector(7 downto 0);
        DQ_reg2  :  IN std_logic_vector(7 downto 0);
        DQ_reg3  :  IN std_logic_vector(7 downto 0);
        D_mem    :  IN NATURAL;
        DLP_reg  :  IN NATURAL;
        D_dlp_act:  IN std_logic_vector(1 downto 0);
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF D_dlp_act = "11" THEN
            ASSERT to_nat(DQ_reg0) = DLP_reg
                REPORT "Read DLP Register: expected data = " &
                to_int_str(DLP_reg) & " got " & to_int_str(DQ_reg0)
                SEVERITY error;
            ASSERT to_nat(DQ_reg0) /= DLP_reg
                REPORT "Read DLP Register: OK - "& to_int_str(DQ_reg0)
                SEVERITY note;
            ASSERT to_nat(DQ_reg1) = DLP_reg
                REPORT "Read DLP Register: expected data = " &
                to_int_str(DLP_reg) & " got " & to_int_str(DQ_reg1)
                SEVERITY error;
            ASSERT to_nat(DQ_reg1) /= DLP_reg
                REPORT "Read DLP Register: OK - "& to_int_str(DQ_reg1)
                SEVERITY note;
            ASSERT to_nat(DQ_reg2) = DLP_reg
                REPORT "Read DLP Register: expected data = " &
                to_int_str(DLP_reg) & " got " & to_int_str(DQ_reg2)
                SEVERITY error;
            ASSERT to_nat(DQ_reg2) /= DLP_reg
                REPORT "Read DLP Register: OK - "& to_int_str(DQ_reg2)
                SEVERITY note;
            ASSERT to_nat(DQ_reg3) = DLP_reg
                REPORT "Read DLP Register: expected data = " &
                to_int_str(DLP_reg) & " got " & to_int_str(DQ_reg3)
                SEVERITY error;
            ASSERT to_nat(DQ_reg3) /= DLP_reg
                REPORT "Read DLP Register: OK - "& to_int_str(DQ_reg3)
                SEVERITY note;
        END IF;

        ASSERT to_nat(DQ) = D_mem
            REPORT "READ: expected data  =" &
            to_hex_str(D_mem)&" got " &
            to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ)/=D_mem
            REPORT "READ: OK - "&
            to_hex_str(DQ)
            SEVERITY note;

        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSIF (D_dlp_act = "11") THEN
            IF (to_nat(DQ_reg3)/=DLP_reg OR to_nat(DQ_reg2)/=DLP_reg
            OR to_nat(DQ_reg1)/=DLP_reg OR to_nat(DQ_reg0)/=DLP_reg) THEN
                check_err <= '1';
            END IF;

        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read;

----Check tristated output
    PROCEDURE   Check_Z (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT DQ = 'Z'
            REPORT "output should be HiZ"
            SEVERITY error;

        IF DQ /= 'Z' THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

        ASSERT DQ /= 'Z'
            REPORT "Read OK - output HiZ"
            SEVERITY note;
    END PROCEDURE Check_Z;

----Check unknown
    PROCEDURE   Check_X (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT DQ = 'X'
            REPORT "output should be X"
            SEVERITY error;

        IF DQ /= 'X' THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

        ASSERT DQ /= 'X'
            REPORT "Read OK - output X"
            SEVERITY note;
    END PROCEDURE Check_X;

    PROCEDURE   Check_U (
        DQ   :  IN std_logic;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT DQ = 'U'
            REPORT "output should be U"
            SEVERITY error;

        IF DQ /= 'U' THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

        ASSERT DQ /= 'U'
            REPORT "Read OK - output U"
            SEVERITY note;
    END PROCEDURE Check_U;

----Check read from OTP memory
    PROCEDURE   Check_otp_read (
        DQ     :  IN std_logic_vector(7 downto 0);
        otp_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = otp_mem
            REPORT "READ: expected data  =" &
            to_int_str(otp_mem)&" got " &
            to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ)/=otp_mem
            REPORT "READ: OK - "&
            to_hex_str(DQ)
            SEVERITY note;

        IF to_nat(DQ)/=otp_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_otp_read;

----Check JEDEC manuf. and device ID
    PROCEDURE   Check_read_JID (
        DQ               :  IN std_logic_vector(7 downto 0);
        VDATA            :  IN NATURAL;
        byte_no          :  IN NATURAL;
        SIGNAL check_err :  OUT std_logic) IS
    BEGIN

        ASSERT to_nat(DQ(7 downto 0)) = VDATA
            REPORT "READ CFI: expected data =" &
            to_hex_str(VDATA)&" got " &
            to_hex_str(DQ(7 downto 0))
            SEVERITY error;

        ASSERT to_nat(DQ(7 downto 0))/=VDATA
            REPORT "READ CFI: OK - "&
            to_hex_str(DQ(7 downto 0))
            SEVERITY note;

        IF to_nat(DQ(7 downto 0))/=VDATA THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_JID;

----Check read from OTP memory
    PROCEDURE   Check_read_SFDP (
        DQ     :  IN std_logic_vector(7 downto 0);
        VDATA            :  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = VDATA
            REPORT "READ: expected data  =" &
            to_hex_str(VDATA)&" got " &
            to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ)/=VDATA
            REPORT "READ: OK - "&
            to_hex_str(DQ)
            SEVERITY note;

        IF to_nat(DQ)/=VDATA THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_SFDP;

----Check read Status Register 1
    PROCEDURE   Check_read_sr1 (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Status Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Status Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

    END PROCEDURE Check_read_sr1;

----Check read Status Register 2
    PROCEDURE   Check_read_sr2 (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Status Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Status Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

    END PROCEDURE Check_read_sr2;

----Check read all registers
    PROCEDURE   Check_rdar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read All Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read All Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

    END PROCEDURE Check_rdar;

----Check read Configuration Register
    PROCEDURE   Check_read_config (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Configuration Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Configuration Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

    END PROCEDURE Check_read_config;

----Check read autoboot register
    PROCEDURE   Check_read_autoboot (
        DQ   :  IN std_logic_vector(31 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Autoboot Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Autoboot Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_autoboot;

----Check read Bank register
    PROCEDURE   Check_read_bank (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Bank Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Bank Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_bank;

----Check read ASP register
    PROCEDURE   Check_read_asp (
        DQ   :  IN std_logic_vector(15 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read ASP Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read ASP Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_asp;

----Check read Password Register
    PROCEDURE   Check_read_pass_reg (
        DQ   :  IN std_logic_vector(63 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read Password Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read Password Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_pass_reg;

----Check PPB Lock register
    PROCEDURE   Check_read_ppbl (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read PPB Lock Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read PPB Lock Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_ppbl;

----Check PPB Access register
    PROCEDURE   Check_read_ppbar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read PPB Access Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read PPB Access Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_ppbar;

----Check DYB Access register
    PROCEDURE   Check_read_dybar (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read DYB Access Register: expected data = " &
            to_int_str(D_mem) & " got " & to_int_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read DYB Access Register: OK - "& to_int_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_dybar;

----Check ECC register
    PROCEDURE   Check_read_ecc (
        DQ   :  IN std_logic_vector(7 downto 0);
        D_mem:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = D_mem
            REPORT "Read ECC Register: expected data = " &
            to_hex_str(D_mem) & " got " & to_hex_str(DQ)
            SEVERITY error;

        ASSERT to_nat(DQ) /= D_mem
            REPORT "Read ECC Register: OK - "& to_hex_str(DQ)
            SEVERITY note;
        IF to_nat(DQ)/=D_mem THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;
    END PROCEDURE Check_read_ecc;

----Check PPBLOCK bit
    PROCEDURE   Check_PPBLOCK_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = rd_ppblock_1
                REPORT "ERROR: Expected value PPBLOCK = '1' and got value '0'"
                SEVERITY error;

            IF sts /= rd_ppblock_1 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_ppblock_1
                REPORT "PPBLOCK = '1', PPB array may be programmed or erased"
                SEVERITY note;
        ELSE
            ASSERT sts = rd_ppblock_0
                REPORT "ERROR: Expected value PPBLOCK = '0' and got value '1'"
                SEVERITY error;

            IF sts /= rd_ppblock_0 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_ppblock_0
                REPORT "PPBLOCK = '0', PPB array is protected "
                SEVERITY note;
        END IF;
    END PROCEDURE Check_PPBLOCK_bit;

----Check WIP bit
    PROCEDURE   Check_WIP_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = rd_wip_1
                REPORT "Write in progress "&
                       "ERROR: command should be ignored"
                SEVERITY error;

            IF sts /= rd_wip_1 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_wip_1
                REPORT "Write In progress"
                SEVERITY note;
        ELSE
            ASSERT sts = rd_wip_0
                REPORT "Write is NOT in progress "&
                       "   command NOT accepted"
                SEVERITY error;

            IF sts /= rd_wip_0 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_wip_0
                REPORT "Write is NOT in progress "
                SEVERITY note;
        END IF;
    END PROCEDURE Check_WIP_bit;

----Check WEL bit
    PROCEDURE   Check_WEL_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = rd_wel_1
                REPORT " WEL=0 "&
                       "ERROR: command should be ignored"
                SEVERITY error;

            IF sts /= rd_wel_1 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_wel_1
                REPORT "WEL = 1; Operation in progress"
                SEVERITY note;
        ELSE
            ASSERT sts = rd_wel_0
                REPORT "WEL = 1 "&
                       "ERROR: command NOT accepted"
                SEVERITY error;

            IF sts /= rd_wel_0 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_wel_0
                REPORT " WEL=0; Operation completed "
                SEVERITY note;
        END IF;
    END PROCEDURE Check_WEL_bit;

----Check Erase operation bit
    PROCEDURE   Check_eers_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = erase_nosucc
                REPORT "Erase Operation ERROR"
                SEVERITY error;

            IF sts /= erase_nosucc THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= erase_nosucc
                REPORT "Erase Operation failed"
                SEVERITY note;
        ELSE
            ASSERT sts = erase_succ
                REPORT "Erase Operation successful "
                SEVERITY error;

            IF sts /=  erase_succ THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= erase_succ
                REPORT "Erase Operation OK "
                SEVERITY note;
        END IF;
    END PROCEDURE Check_eers_bit;

----Check Program operation bit
    PROCEDURE   Check_epgm_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = pgm_nosucc
                REPORT "Program Operation ERROR"
                SEVERITY error;

            IF sts /= pgm_nosucc THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= pgm_nosucc
                REPORT "Program Operation failed"
                SEVERITY note;
        ELSE
            ASSERT sts = pgm_succ
                REPORT "Program Operation successful "
                SEVERITY error;

            IF sts /=  pgm_succ THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= pgm_succ
                REPORT "Program Operation OK "

                SEVERITY note;
        END IF;
    END PROCEDURE Check_epgm_bit;

----Check Program Suspend bit
    PROCEDURE Check_PS_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = rd_ps_1
                REPORT "Program Suspend ERROR"
                SEVERITY error;

            IF sts /= rd_ps_1 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_ps_1
                REPORT "Program Suspend mode: active"
                SEVERITY note;
        ELSE
            ASSERT sts = rd_ps_0
                REPORT "Program Suspend successful "
                SEVERITY error;

            IF sts /=  rd_ps_0 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_ps_0
                REPORT "Program not in Suspend "

                SEVERITY note;
        END IF;
    END PROCEDURE Check_PS_bit;

----Check Erase Suspend bit
    PROCEDURE Check_ES_bit (
        DQ   :  IN std_logic;
        sts  :  IN  status_type;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        IF DQ = '1' THEN
            ASSERT sts = rd_es_1
                REPORT "Erase Suspend ERROR"
                SEVERITY error;

            IF sts /= rd_es_1 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_es_1
                REPORT "Erase Suspend mode: active"
                SEVERITY note;
        ELSE
            ASSERT sts = rd_es_0
                REPORT "Erase Suspend successful "
                SEVERITY error;

            IF sts /=  rd_es_0 THEN
                check_err <= '1';
            ELSE
                check_err <= '0';
            END IF;

            ASSERT sts /= rd_es_0
                REPORT "Erase not in Suspend "

                SEVERITY note;
        END IF;
    END PROCEDURE Check_ES_bit;

----Check read DLP Register
    PROCEDURE   Check_read_dlp (
        DQ     :  IN std_logic_vector(7 downto 0);
        DLP_reg:  IN NATURAL;
        SIGNAL check_err:  OUT std_logic) IS
    BEGIN
        ASSERT to_nat(DQ) = DLP_reg
            REPORT "Read DLP Register: expected data = " &
            to_int_str(DLP_reg) & " got " & to_int_str(DQ)
            SEVERITY error;
        ASSERT to_nat(DQ) /= DLP_reg
            REPORT "Read DLP Register: OK - "& to_int_str(DQ)
            SEVERITY note;

        IF to_nat(DQ)/=DLP_reg THEN
            check_err <= '1';
        ELSE
            check_err <= '0';
        END IF;

    END PROCEDURE Check_read_dlp;

END PACKAGE BODY spansion_tc_pkg;
