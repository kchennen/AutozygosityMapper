--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:20:33 CET

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
-- TOC entry 17 (class 2615 OID 22236)
-- Name: am_rat; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am_rat;


ALTER SCHEMA am_rat OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 280 (class 1259 OID 22237)
-- Name: analyses; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.analyses (
    analysis_no integer NOT NULL,
    project_no integer NOT NULL,
    analysis_name character varying(40) NOT NULL,
    max_block_length numeric(5,0) NOT NULL,
    analysis_description character varying(400),
    max_score numeric(5,0),
    homogeneity_required boolean,
    lower_limit numeric(5,0),
    date timestamp without time zone,
    exclusion_length numeric(6,0),
    completed boolean DEFAULT false,
    deleted date,
    archived date,
    autozygosity_required boolean
);


ALTER TABLE am_rat.analyses OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 22241)
-- Name: chips; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am_rat.chips OWNER TO postgres;

--
-- TOC entry 356 (class 1259 OID 24797)
-- Name: marker_alleles; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.marker_alleles (
    chip_no smallint NOT NULL,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a character(1) NOT NULL,
    allele_b character(1) NOT NULL
);


ALTER TABLE am_rat.marker_alleles OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 22244)
-- Name: markers; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.markers (
    dbsnp_no numeric(8,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0)
);


ALTER TABLE am_rat.markers OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 22247)
-- Name: markers2chips; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.markers2chips (
    chip_no smallint,
    dbsnp_no integer,
    marker_name character varying(100) NOT NULL,
    remarks character varying(100)
);


ALTER TABLE am_rat.markers2chips OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 22250)
-- Name: projects; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.projects (
    project_no integer NOT NULL,
    project_name character varying(40) NOT NULL,
    user_login character varying(20) NOT NULL,
    access_restricted boolean DEFAULT true,
    marker_count integer,
    unique_id character varying(30),
    creation_date date,
    vcf_build smallint,
    completed boolean DEFAULT false,
    deleted date,
    archived date,
    genotypes_count integer
);


ALTER TABLE am_rat.projects OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 22255)
-- Name: projects_permissions; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am_rat.projects_permissions OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 22258)
-- Name: sequence_analyses; Type: SEQUENCE; Schema: am_rat; Owner: postgres
--

CREATE SEQUENCE am_rat.sequence_analyses
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_rat.sequence_analyses OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 22260)
-- Name: sequence_projects; Type: SEQUENCE; Schema: am_rat; Owner: postgres
--

CREATE SEQUENCE am_rat.sequence_projects
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_rat.sequence_projects OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 22262)
-- Name: variants; Type: TABLE; Schema: am_rat; Owner: postgres
--

CREATE TABLE am_rat.variants (
    marker_no numeric(10,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0) NOT NULL,
    source character(1)
);


ALTER TABLE am_rat.variants OWNER TO postgres;

--
-- TOC entry 271564 (class 2606 OID 22266)
-- Name: analyses pk_am_rat_analyses; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.analyses
    ADD CONSTRAINT pk_am_rat_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271566 (class 2606 OID 22268)
-- Name: chips pk_am_rat_chips; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.chips
    ADD CONSTRAINT pk_am_rat_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271571 (class 2606 OID 22270)
-- Name: markers pk_am_rat_markers; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.markers
    ADD CONSTRAINT pk_am_rat_markers PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271577 (class 2606 OID 22272)
-- Name: projects pk_am_rat_projects; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects
    ADD CONSTRAINT pk_am_rat_projects PRIMARY KEY (project_no);


--
-- TOC entry 271583 (class 2606 OID 22274)
-- Name: projects_permissions pk_am_rat_projects_permissions; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects_permissions
    ADD CONSTRAINT pk_am_rat_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271587 (class 2606 OID 22276)
-- Name: variants pk_ratvariants; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.variants
    ADD CONSTRAINT pk_ratvariants PRIMARY KEY (marker_no);


--
-- TOC entry 271579 (class 2606 OID 22278)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271568 (class 2606 OID 22280)
-- Name: chips u_am_rat_chips_chip_name; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.chips
    ADD CONSTRAINT u_am_rat_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271575 (class 2606 OID 22282)
-- Name: markers2chips u_am_rat_markers2chips_marker_name; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.markers2chips
    ADD CONSTRAINT u_am_rat_markers2chips_marker_name UNIQUE (marker_name, chip_no);


--
-- TOC entry 271581 (class 2606 OID 22284)
-- Name: projects u_am_rat_projects_project_name; Type: CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects
    ADD CONSTRAINT u_am_rat_projects_project_name UNIQUE (project_name);


--
-- TOC entry 271562 (class 1259 OID 22285)
-- Name: fki_am_rat_analyses_project_no; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX fki_am_rat_analyses_project_no ON am_rat.analyses USING btree (project_no);


--
-- TOC entry 271572 (class 1259 OID 22286)
-- Name: i_am_rat_markers2chips_chip_no; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX i_am_rat_markers2chips_chip_no ON am_rat.markers2chips USING btree (chip_no);


--
-- TOC entry 271573 (class 1259 OID 22287)
-- Name: i_am_rat_markers2chips_dbsnp_no; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX i_am_rat_markers2chips_dbsnp_no ON am_rat.markers2chips USING btree (dbsnp_no);


--
-- TOC entry 271569 (class 1259 OID 22288)
-- Name: i_am_rat_markers_chromosome_position; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX i_am_rat_markers_chromosome_position ON am_rat.markers USING btree (chromosome, "position");


--
-- TOC entry 271584 (class 1259 OID 22289)
-- Name: i_ratvariants_chromosome_position; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX i_ratvariants_chromosome_position ON am_rat.variants USING btree (chromosome, "position");


--
-- TOC entry 271585 (class 1259 OID 22290)
-- Name: i_ratvariants_source; Type: INDEX; Schema: am_rat; Owner: postgres
--

CREATE INDEX i_ratvariants_source ON am_rat.variants USING btree (source);


--
-- TOC entry 271588 (class 2606 OID 22291)
-- Name: analyses fk_am_rat_analyses_project_no; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.analyses
    ADD CONSTRAINT fk_am_rat_analyses_project_no FOREIGN KEY (project_no) REFERENCES am_rat.projects(project_no);


--
-- TOC entry 271589 (class 2606 OID 22296)
-- Name: markers2chips fk_am_rat_markers2chips_2_chips; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.markers2chips
    ADD CONSTRAINT fk_am_rat_markers2chips_2_chips FOREIGN KEY (chip_no) REFERENCES am_rat.chips(chip_no);


--
-- TOC entry 271590 (class 2606 OID 22301)
-- Name: markers2chips fk_am_rat_markers2chips_2_markers; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.markers2chips
    ADD CONSTRAINT fk_am_rat_markers2chips_2_markers FOREIGN KEY (dbsnp_no) REFERENCES am_rat.markers(dbsnp_no);


--
-- TOC entry 271591 (class 2606 OID 22306)
-- Name: projects_permissions fk_am_rat_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects_permissions
    ADD CONSTRAINT fk_am_rat_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am_rat.projects(project_no);


--
-- TOC entry 271592 (class 2606 OID 26324)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271593 (class 2606 OID 24803)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am_rat; Owner: postgres
--

ALTER TABLE ONLY am_rat.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am_rat.chips(chip_no);


--
-- TOC entry 271725 (class 0 OID 0)
-- Dependencies: 17
-- Name: SCHEMA am_rat; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am_rat TO PUBLIC;


--
-- TOC entry 271726 (class 0 OID 0)
-- Dependencies: 280
-- Name: TABLE analyses; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.analyses TO PUBLIC;


--
-- TOC entry 271727 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE chips; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.chips TO PUBLIC;


--
-- TOC entry 271728 (class 0 OID 0)
-- Dependencies: 356
-- Name: TABLE marker_alleles; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT ALL ON TABLE am_rat.marker_alleles TO genetik;


--
-- TOC entry 271729 (class 0 OID 0)
-- Dependencies: 282
-- Name: TABLE markers; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.markers TO PUBLIC;


--
-- TOC entry 271730 (class 0 OID 0)
-- Dependencies: 283
-- Name: TABLE markers2chips; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.markers2chips TO PUBLIC;


--
-- TOC entry 271731 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE projects; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.projects TO PUBLIC;


--
-- TOC entry 271732 (class 0 OID 0)
-- Dependencies: 285
-- Name: TABLE projects_permissions; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.projects_permissions TO PUBLIC;


--
-- TOC entry 271733 (class 0 OID 0)
-- Dependencies: 286
-- Name: SEQUENCE sequence_analyses; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT ALL ON SEQUENCE am_rat.sequence_analyses TO genetik;
GRANT ALL ON SEQUENCE am_rat.sequence_analyses TO PUBLIC;


--
-- TOC entry 271734 (class 0 OID 0)
-- Dependencies: 287
-- Name: SEQUENCE sequence_projects; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT ALL ON SEQUENCE am_rat.sequence_projects TO genetik;
GRANT ALL ON SEQUENCE am_rat.sequence_projects TO PUBLIC;


--
-- TOC entry 271735 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE variants; Type: ACL; Schema: am_rat; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_rat.variants TO PUBLIC;
GRANT ALL ON TABLE am_rat.variants TO genetik;


-- Completed on 2022-03-15 14:20:40 CET

--
-- PostgreSQL database dump complete
--

