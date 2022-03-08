--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:19:03 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 11 (class 2615 OID 16385)
-- Name: am; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am;


ALTER SCHEMA am OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 242 (class 1259 OID 16390)
-- Name: allelefrequencies; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.allelefrequencies (
    dbsnp_no integer NOT NULL,
    population_no smallint NOT NULL,
    freq_hom numeric(4,3) NOT NULL
);


ALTER TABLE am.allelefrequencies OWNER TO genetik;

--
-- TOC entry 243 (class 1259 OID 16393)
-- Name: analyses; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.analyses (
    analysis_no integer NOT NULL,
    project_no integer NOT NULL,
    analysis_name character varying(40) NOT NULL,
    max_block_length numeric(5,0) NOT NULL,
    analysis_description character varying(400),
    max_score integer,
    homogeneity_required boolean,
    lower_limit numeric(5,0),
    date timestamp without time zone,
    exclusion_length numeric(6,0),
    completed boolean DEFAULT false,
    archived date,
    deleted date,
    autozygosity_required boolean DEFAULT false
);


ALTER TABLE am.analyses OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16397)
-- Name: chips; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am.chips OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 20439)
-- Name: marker_alleles; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.marker_alleles (
    chip_no smallint NOT NULL,
    dbnsp_no integer,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a text NOT NULL,
    allele_b text NOT NULL
);


ALTER TABLE am.marker_alleles OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16400)
-- Name: markers; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.markers (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16403)
-- Name: markers2chips; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.markers2chips (
    chip_no smallint,
    marker_name character varying(100) NOT NULL,
    remarks character varying(100),
    dbsnp_no integer
);


ALTER TABLE am.markers2chips OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16406)
-- Name: markers_1; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_1 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_1 OWNER TO genetik;

--
-- TOC entry 248 (class 1259 OID 16409)
-- Name: markers_10; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_10 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_10 OWNER TO genetik;

--
-- TOC entry 249 (class 1259 OID 16412)
-- Name: markers_11; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_11 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_11 OWNER TO genetik;

--
-- TOC entry 250 (class 1259 OID 16415)
-- Name: markers_12; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_12 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_12 OWNER TO genetik;

--
-- TOC entry 251 (class 1259 OID 16418)
-- Name: markers_13; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_13 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_13 OWNER TO genetik;

--
-- TOC entry 252 (class 1259 OID 16421)
-- Name: markers_14; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_14 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_14 OWNER TO genetik;

--
-- TOC entry 253 (class 1259 OID 16424)
-- Name: markers_15; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_15 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_15 OWNER TO genetik;

--
-- TOC entry 254 (class 1259 OID 16427)
-- Name: markers_16; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_16 (
    chromosome smallint,
    dbsnp_no numeric(10,0) NOT NULL,
    "position" numeric(10,0),
    removed boolean
);


ALTER TABLE am.markers_16 OWNER TO genetik;

--
-- TOC entry 255 (class 1259 OID 16430)
-- Name: markers_17; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_17 (
    chromosome smallint NOT NULL,
    dbsnp_no integer NOT NULL,
    "position" integer NOT NULL,
    removed boolean
);


ALTER TABLE am.markers_17 OWNER TO genetik;

--
-- TOC entry 256 (class 1259 OID 16433)
-- Name: markers_18; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_18 (
    chromosome smallint NOT NULL,
    dbsnp_no integer NOT NULL,
    "position" integer NOT NULL,
    removed boolean
);


ALTER TABLE am.markers_18 OWNER TO genetik;

--
-- TOC entry 257 (class 1259 OID 16436)
-- Name: markers_19; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_19 (
    chromosome smallint NOT NULL,
    dbsnp_no integer NOT NULL,
    "position" integer NOT NULL,
    removed boolean
);


ALTER TABLE am.markers_19 OWNER TO genetik;

--
-- TOC entry 258 (class 1259 OID 16439)
-- Name: markers_2; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_2 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_2 OWNER TO genetik;

--
-- TOC entry 259 (class 1259 OID 16442)
-- Name: markers_3; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_3 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_3 OWNER TO genetik;

--
-- TOC entry 260 (class 1259 OID 16445)
-- Name: markers_4; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_4 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_4 OWNER TO genetik;

--
-- TOC entry 261 (class 1259 OID 16448)
-- Name: markers_5; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_5 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_5 OWNER TO genetik;

--
-- TOC entry 262 (class 1259 OID 16451)
-- Name: markers_6; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_6 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_6 OWNER TO genetik;

--
-- TOC entry 263 (class 1259 OID 16454)
-- Name: markers_7; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_7 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_7 OWNER TO genetik;

--
-- TOC entry 264 (class 1259 OID 16457)
-- Name: markers_9; Type: TABLE; Schema: am; Owner: genetik
--

CREATE TABLE am.markers_9 (
    chromosome smallint,
    dbsnp_no integer NOT NULL,
    "position" integer,
    removed boolean
);


ALTER TABLE am.markers_9 OWNER TO genetik;

--
-- TOC entry 265 (class 1259 OID 16460)
-- Name: populations; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.populations (
    population_no smallint NOT NULL,
    population_name character varying(100) NOT NULL
);


ALTER TABLE am.populations OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 16463)
-- Name: projects; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.projects (
    project_no integer NOT NULL,
    project_name character varying(40) NOT NULL,
    user_login character varying(20) NOT NULL,
    access_restricted boolean DEFAULT true,
    marker_count integer,
    unique_id character varying(30),
    creation_date date,
    vcf_build smallint,
    completed boolean DEFAULT false,
    date timestamp without time zone,
    deleted date,
    archived date,
    genotypes_count bigint
);


ALTER TABLE am.projects OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 16468)
-- Name: projects_permissions; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am.projects_permissions OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16386)
-- Name: sequence_analyses; Type: SEQUENCE; Schema: am; Owner: postgres
--

CREATE SEQUENCE am.sequence_analyses
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am.sequence_analyses OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16388)
-- Name: sequence_projects; Type: SEQUENCE; Schema: am; Owner: postgres
--

CREATE SEQUENCE am.sequence_projects
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am.sequence_projects OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 16471)
-- Name: users; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.users (
    user_login character varying(20) NOT NULL,
    user_password_old character varying(20),
    user_name character varying(100) NOT NULL,
    user_email character varying(100) NOT NULL,
    organisation character varying(100),
    user_password text NOT NULL
);


ALTER TABLE am.users OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 16474)
-- Name: variants; Type: TABLE; Schema: am; Owner: postgres
--

CREATE TABLE am.variants (
    marker_no numeric(10,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0) NOT NULL,
    source character(1)
);


ALTER TABLE am.variants OWNER TO postgres;

--
-- TOC entry 271637 (class 2606 OID 16478)
-- Name: markers_17 markers_17_pkey; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_17
    ADD CONSTRAINT markers_17_pkey PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271640 (class 2606 OID 16480)
-- Name: markers_18 markers_18_pkey; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_18
    ADD CONSTRAINT markers_18_pkey PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271643 (class 2606 OID 16482)
-- Name: markers_19 markers_19_pkey; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_19
    ADD CONSTRAINT markers_19_pkey PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271585 (class 2606 OID 16484)
-- Name: allelefrequencies pk_allelefrequencies; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.allelefrequencies
    ADD CONSTRAINT pk_allelefrequencies PRIMARY KEY (dbsnp_no, population_no);


--
-- TOC entry 271588 (class 2606 OID 16486)
-- Name: analyses pk_analyses; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.analyses
    ADD CONSTRAINT pk_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271592 (class 2606 OID 16488)
-- Name: chips pk_chips; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.chips
    ADD CONSTRAINT pk_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271598 (class 2606 OID 16490)
-- Name: markers pk_hmmarkers; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.markers
    ADD CONSTRAINT pk_hmmarkers PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271606 (class 2606 OID 16492)
-- Name: markers_1 pk_hmmarkers_1; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_1
    ADD CONSTRAINT pk_hmmarkers_1 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271610 (class 2606 OID 16494)
-- Name: markers_10 pk_hmmarkers_10; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_10
    ADD CONSTRAINT pk_hmmarkers_10 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271614 (class 2606 OID 16496)
-- Name: markers_11 pk_hmmarkers_11; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_11
    ADD CONSTRAINT pk_hmmarkers_11 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271618 (class 2606 OID 16498)
-- Name: markers_12 pk_hmmarkers_12; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_12
    ADD CONSTRAINT pk_hmmarkers_12 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271622 (class 2606 OID 16500)
-- Name: markers_13 pk_hmmarkers_13; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_13
    ADD CONSTRAINT pk_hmmarkers_13 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271626 (class 2606 OID 16502)
-- Name: markers_14 pk_hmmarkers_14; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_14
    ADD CONSTRAINT pk_hmmarkers_14 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271630 (class 2606 OID 16504)
-- Name: markers_15 pk_hmmarkers_15; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_15
    ADD CONSTRAINT pk_hmmarkers_15 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271634 (class 2606 OID 16506)
-- Name: markers_16 pk_hmmarkers_16; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_16
    ADD CONSTRAINT pk_hmmarkers_16 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271647 (class 2606 OID 16508)
-- Name: markers_2 pk_hmmarkers_2; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_2
    ADD CONSTRAINT pk_hmmarkers_2 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271651 (class 2606 OID 16510)
-- Name: markers_3 pk_hmmarkers_3; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_3
    ADD CONSTRAINT pk_hmmarkers_3 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271655 (class 2606 OID 16512)
-- Name: markers_4 pk_hmmarkers_4; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_4
    ADD CONSTRAINT pk_hmmarkers_4 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271659 (class 2606 OID 16514)
-- Name: markers_5 pk_hmmarkers_5; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_5
    ADD CONSTRAINT pk_hmmarkers_5 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271663 (class 2606 OID 16516)
-- Name: markers_6 pk_hmmarkers_6; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_6
    ADD CONSTRAINT pk_hmmarkers_6 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271667 (class 2606 OID 16518)
-- Name: markers_7 pk_hmmarkers_7; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_7
    ADD CONSTRAINT pk_hmmarkers_7 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271671 (class 2606 OID 16520)
-- Name: markers_9 pk_hmmarkers_9; Type: CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.markers_9
    ADD CONSTRAINT pk_hmmarkers_9 PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271673 (class 2606 OID 16522)
-- Name: populations pk_populations; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.populations
    ADD CONSTRAINT pk_populations PRIMARY KEY (population_no);


--
-- TOC entry 271677 (class 2606 OID 16524)
-- Name: projects pk_projects; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects
    ADD CONSTRAINT pk_projects PRIMARY KEY (project_no);


--
-- TOC entry 271683 (class 2606 OID 16526)
-- Name: projects_permissions pk_projects_permissions; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects_permissions
    ADD CONSTRAINT pk_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271685 (class 2606 OID 16528)
-- Name: users pk_users; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.users
    ADD CONSTRAINT pk_users PRIMARY KEY (user_login);


--
-- TOC entry 271689 (class 2606 OID 16530)
-- Name: variants pk_variants; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.variants
    ADD CONSTRAINT pk_variants PRIMARY KEY (marker_no);


--
-- TOC entry 271679 (class 2606 OID 16539)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271590 (class 2606 OID 22066)
-- Name: analyses u_analysis_name; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.analyses
    ADD CONSTRAINT u_analysis_name UNIQUE (analysis_name, project_no);


--
-- TOC entry 271594 (class 2606 OID 16541)
-- Name: chips u_chips_chip_name; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.chips
    ADD CONSTRAINT u_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271602 (class 2606 OID 16543)
-- Name: markers2chips u_markers2chips_marker_name; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.markers2chips
    ADD CONSTRAINT u_markers2chips_marker_name UNIQUE (marker_name, chip_no);


--
-- TOC entry 271675 (class 2606 OID 16545)
-- Name: populations u_populations_population_name; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.populations
    ADD CONSTRAINT u_populations_population_name UNIQUE (population_name);


--
-- TOC entry 271681 (class 2606 OID 16610)
-- Name: projects u_projects_project_name; Type: CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects
    ADD CONSTRAINT u_projects_project_name UNIQUE (user_login, project_name);


--
-- TOC entry 271586 (class 1259 OID 16548)
-- Name: fki_analyses_project_no; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX fki_analyses_project_no ON am.analyses USING btree (project_no);


--
-- TOC entry 271607 (class 1259 OID 16549)
-- Name: i_hmmarkers_10_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_10_chromosome ON am.markers_10 USING btree (chromosome);


--
-- TOC entry 271608 (class 1259 OID 16550)
-- Name: i_hmmarkers_10_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_10_chromosome_position ON am.markers_10 USING btree (chromosome, "position");


--
-- TOC entry 271611 (class 1259 OID 16551)
-- Name: i_hmmarkers_11_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_11_chromosome ON am.markers_11 USING btree (chromosome);


--
-- TOC entry 271612 (class 1259 OID 16552)
-- Name: i_hmmarkers_11_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_11_chromosome_position ON am.markers_11 USING btree (chromosome, "position");


--
-- TOC entry 271615 (class 1259 OID 16553)
-- Name: i_hmmarkers_12_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_12_chromosome ON am.markers_12 USING btree (chromosome);


--
-- TOC entry 271616 (class 1259 OID 16554)
-- Name: i_hmmarkers_12_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_12_chromosome_position ON am.markers_12 USING btree (chromosome, "position");


--
-- TOC entry 271619 (class 1259 OID 16555)
-- Name: i_hmmarkers_13_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_13_chromosome ON am.markers_13 USING btree (chromosome);


--
-- TOC entry 271620 (class 1259 OID 16556)
-- Name: i_hmmarkers_13_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_13_chromosome_position ON am.markers_13 USING btree (chromosome, "position");


--
-- TOC entry 271623 (class 1259 OID 16557)
-- Name: i_hmmarkers_14_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_14_chromosome ON am.markers_14 USING btree (chromosome);


--
-- TOC entry 271624 (class 1259 OID 16558)
-- Name: i_hmmarkers_14_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_14_chromosome_position ON am.markers_14 USING btree (chromosome, "position");


--
-- TOC entry 271627 (class 1259 OID 16559)
-- Name: i_hmmarkers_15_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_15_chromosome ON am.markers_15 USING btree (chromosome);


--
-- TOC entry 271628 (class 1259 OID 16560)
-- Name: i_hmmarkers_15_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_15_chromosome_position ON am.markers_15 USING btree (chromosome, "position");


--
-- TOC entry 271631 (class 1259 OID 16561)
-- Name: i_hmmarkers_16_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_16_chromosome ON am.markers_16 USING btree (chromosome);


--
-- TOC entry 271632 (class 1259 OID 16562)
-- Name: i_hmmarkers_16_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_16_chromosome_position ON am.markers_16 USING btree (chromosome, "position");


--
-- TOC entry 271603 (class 1259 OID 16563)
-- Name: i_hmmarkers_1_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_1_chromosome ON am.markers_1 USING btree (chromosome);


--
-- TOC entry 271604 (class 1259 OID 16564)
-- Name: i_hmmarkers_1_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_1_chromosome_position ON am.markers_1 USING btree (chromosome, "position");


--
-- TOC entry 271644 (class 1259 OID 16565)
-- Name: i_hmmarkers_2_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_2_chromosome ON am.markers_2 USING btree (chromosome);


--
-- TOC entry 271645 (class 1259 OID 16566)
-- Name: i_hmmarkers_2_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_2_chromosome_position ON am.markers_2 USING btree (chromosome, "position");


--
-- TOC entry 271648 (class 1259 OID 16567)
-- Name: i_hmmarkers_3_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_3_chromosome ON am.markers_3 USING btree (chromosome);


--
-- TOC entry 271649 (class 1259 OID 16568)
-- Name: i_hmmarkers_3_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_3_chromosome_position ON am.markers_3 USING btree (chromosome, "position");


--
-- TOC entry 271652 (class 1259 OID 16569)
-- Name: i_hmmarkers_4_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_4_chromosome ON am.markers_4 USING btree (chromosome);


--
-- TOC entry 271653 (class 1259 OID 16570)
-- Name: i_hmmarkers_4_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_4_chromosome_position ON am.markers_4 USING btree (chromosome, "position");


--
-- TOC entry 271656 (class 1259 OID 16571)
-- Name: i_hmmarkers_5_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_5_chromosome ON am.markers_5 USING btree (chromosome);


--
-- TOC entry 271657 (class 1259 OID 16572)
-- Name: i_hmmarkers_5_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_5_chromosome_position ON am.markers_5 USING btree (chromosome, "position");


--
-- TOC entry 271660 (class 1259 OID 16573)
-- Name: i_hmmarkers_6_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_6_chromosome ON am.markers_6 USING btree (chromosome);


--
-- TOC entry 271661 (class 1259 OID 16574)
-- Name: i_hmmarkers_6_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_6_chromosome_position ON am.markers_6 USING btree (chromosome, "position");


--
-- TOC entry 271664 (class 1259 OID 16575)
-- Name: i_hmmarkers_7_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_7_chromosome ON am.markers_7 USING btree (chromosome);


--
-- TOC entry 271665 (class 1259 OID 16576)
-- Name: i_hmmarkers_7_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_7_chromosome_position ON am.markers_7 USING btree (chromosome, "position");


--
-- TOC entry 271668 (class 1259 OID 16577)
-- Name: i_hmmarkers_9_chromosome; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_9_chromosome ON am.markers_9 USING btree (chromosome);


--
-- TOC entry 271669 (class 1259 OID 16578)
-- Name: i_hmmarkers_9_chromosome_position; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX i_hmmarkers_9_chromosome_position ON am.markers_9 USING btree (chromosome, "position");


--
-- TOC entry 271595 (class 1259 OID 16579)
-- Name: i_hmmarkers_chromosome; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_hmmarkers_chromosome ON am.markers USING btree (chromosome);


--
-- TOC entry 271596 (class 1259 OID 16580)
-- Name: i_hmmarkers_chromosome_position; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_hmmarkers_chromosome_position ON am.markers USING btree (chromosome, "position");


--
-- TOC entry 271599 (class 1259 OID 16581)
-- Name: i_markers2chips_chip_no; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_markers2chips_chip_no ON am.markers2chips USING btree (chip_no);


--
-- TOC entry 271600 (class 1259 OID 16582)
-- Name: i_markers2chips_dbsnp_no; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_markers2chips_dbsnp_no ON am.markers2chips USING btree (dbsnp_no);


--
-- TOC entry 271686 (class 1259 OID 16583)
-- Name: i_variants_chromosome_position; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_variants_chromosome_position ON am.variants USING btree (chromosome, "position");


--
-- TOC entry 271687 (class 1259 OID 16585)
-- Name: i_variants_source; Type: INDEX; Schema: am; Owner: postgres
--

CREATE INDEX i_variants_source ON am.variants USING btree (source);


--
-- TOC entry 271635 (class 1259 OID 16586)
-- Name: markers_17_chromosome_position_idx; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX markers_17_chromosome_position_idx ON am.markers_17 USING btree (chromosome, "position");


--
-- TOC entry 271638 (class 1259 OID 16587)
-- Name: markers_18_chromosome_position_idx; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX markers_18_chromosome_position_idx ON am.markers_18 USING btree (chromosome, "position");


--
-- TOC entry 271641 (class 1259 OID 16588)
-- Name: markers_19_chromosome_position_idx; Type: INDEX; Schema: am; Owner: genetik
--

CREATE INDEX markers_19_chromosome_position_idx ON am.markers_19 USING btree (chromosome, "position");


--
-- TOC entry 271690 (class 2606 OID 16589)
-- Name: allelefrequencies fk_allelefrequencies_2_populations; Type: FK CONSTRAINT; Schema: am; Owner: genetik
--

ALTER TABLE ONLY am.allelefrequencies
    ADD CONSTRAINT fk_allelefrequencies_2_populations FOREIGN KEY (population_no) REFERENCES am.populations(population_no);


--
-- TOC entry 271691 (class 2606 OID 16594)
-- Name: analyses fk_analyses_project_no; Type: FK CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.analyses
    ADD CONSTRAINT fk_analyses_project_no FOREIGN KEY (project_no) REFERENCES am.projects(project_no);


--
-- TOC entry 271692 (class 2606 OID 16599)
-- Name: markers2chips fk_markers2chips_2_chips; Type: FK CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.markers2chips
    ADD CONSTRAINT fk_markers2chips_2_chips FOREIGN KEY (chip_no) REFERENCES am.chips(chip_no);


--
-- TOC entry 271693 (class 2606 OID 26294)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271694 (class 2606 OID 16604)
-- Name: projects_permissions fk_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am.projects(project_no);


--
-- TOC entry 271695 (class 2606 OID 20445)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am; Owner: postgres
--

ALTER TABLE ONLY am.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am.chips(chip_no);


--
-- TOC entry 271827 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA am; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am TO PUBLIC;


--
-- TOC entry 271828 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE allelefrequencies; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.allelefrequencies TO PUBLIC;


--
-- TOC entry 271829 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE analyses; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.analyses TO PUBLIC;


--
-- TOC entry 271830 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE chips; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.chips TO PUBLIC;


--
-- TOC entry 271831 (class 0 OID 0)
-- Dependencies: 270
-- Name: TABLE marker_alleles; Type: ACL; Schema: am; Owner: postgres
--

GRANT ALL ON TABLE am.marker_alleles TO genetik;


--
-- TOC entry 271832 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE markers; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers TO PUBLIC;
GRANT ALL ON TABLE am.markers TO genetik;


--
-- TOC entry 271833 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE markers2chips; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers2chips TO PUBLIC;


--
-- TOC entry 271834 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE markers_1; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_1 TO PUBLIC;


--
-- TOC entry 271835 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE markers_10; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_10 TO PUBLIC;


--
-- TOC entry 271836 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE markers_11; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_11 TO PUBLIC;


--
-- TOC entry 271837 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE markers_12; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_12 TO PUBLIC;


--
-- TOC entry 271838 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE markers_13; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_13 TO PUBLIC;


--
-- TOC entry 271839 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE markers_14; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_14 TO PUBLIC;


--
-- TOC entry 271840 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE markers_15; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_15 TO PUBLIC;


--
-- TOC entry 271841 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE markers_16; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_16 TO PUBLIC;


--
-- TOC entry 271842 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE markers_2; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_2 TO PUBLIC;


--
-- TOC entry 271843 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE markers_3; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_3 TO PUBLIC;


--
-- TOC entry 271844 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE markers_4; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_4 TO PUBLIC;


--
-- TOC entry 271845 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE markers_5; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_5 TO PUBLIC;


--
-- TOC entry 271846 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE markers_6; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_6 TO PUBLIC;


--
-- TOC entry 271847 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE markers_7; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_7 TO PUBLIC;


--
-- TOC entry 271848 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE markers_9; Type: ACL; Schema: am; Owner: genetik
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.markers_9 TO PUBLIC;


--
-- TOC entry 271849 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE populations; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.populations TO PUBLIC;


--
-- TOC entry 271850 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE projects; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.projects TO PUBLIC;


--
-- TOC entry 271851 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE projects_permissions; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.projects_permissions TO PUBLIC;


--
-- TOC entry 271852 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE sequence_analyses; Type: ACL; Schema: am; Owner: postgres
--

GRANT ALL ON SEQUENCE am.sequence_analyses TO genetik;
GRANT ALL ON SEQUENCE am.sequence_analyses TO PUBLIC;


--
-- TOC entry 271853 (class 0 OID 0)
-- Dependencies: 241
-- Name: SEQUENCE sequence_projects; Type: ACL; Schema: am; Owner: postgres
--

GRANT ALL ON SEQUENCE am.sequence_projects TO genetik;
GRANT ALL ON SEQUENCE am.sequence_projects TO PUBLIC;


--
-- TOC entry 271854 (class 0 OID 0)
-- Dependencies: 268
-- Name: TABLE users; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.users TO PUBLIC;


--
-- TOC entry 271855 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE variants; Type: ACL; Schema: am; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am.variants TO PUBLIC;
GRANT ALL ON TABLE am.variants TO genetik;


-- Completed on 2022-03-15 14:19:10 CET

--
-- PostgreSQL database dump complete
--

