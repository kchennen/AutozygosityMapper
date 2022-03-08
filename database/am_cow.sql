--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:19:21 CET

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
-- TOC entry 15 (class 2615 OID 22161)
-- Name: am_cow; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am_cow;


ALTER SCHEMA am_cow OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 271 (class 1259 OID 22162)
-- Name: analyses; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.analyses (
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
    archived date,
    deleted date,
    autozygosity_required boolean
);


ALTER TABLE am_cow.analyses OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 22166)
-- Name: chips; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am_cow.chips OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 24786)
-- Name: marker_alleles; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.marker_alleles (
    chip_no smallint NOT NULL,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a character(1) NOT NULL,
    allele_b character(1) NOT NULL
);


ALTER TABLE am_cow.marker_alleles OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 22169)
-- Name: markers; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.markers (
    dbsnp_no numeric(8,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0)
);


ALTER TABLE am_cow.markers OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 22172)
-- Name: markers2chips; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.markers2chips (
    chip_no smallint,
    dbsnp_no integer,
    marker_name character varying(100) NOT NULL,
    remarks character varying(100)
);


ALTER TABLE am_cow.markers2chips OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 22175)
-- Name: projects; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.projects (
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


ALTER TABLE am_cow.projects OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 22180)
-- Name: projects_permissions; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am_cow.projects_permissions OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 22183)
-- Name: sequence_analyses; Type: SEQUENCE; Schema: am_cow; Owner: postgres
--

CREATE SEQUENCE am_cow.sequence_analyses
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_cow.sequence_analyses OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 22185)
-- Name: sequence_projects; Type: SEQUENCE; Schema: am_cow; Owner: postgres
--

CREATE SEQUENCE am_cow.sequence_projects
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_cow.sequence_projects OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 22187)
-- Name: variants; Type: TABLE; Schema: am_cow; Owner: postgres
--

CREATE TABLE am_cow.variants (
    marker_no numeric(10,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0) NOT NULL,
    source character(1)
);


ALTER TABLE am_cow.variants OWNER TO postgres;

--
-- TOC entry 271564 (class 2606 OID 22193)
-- Name: analyses pk_am_cow_analyses; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.analyses
    ADD CONSTRAINT pk_am_cow_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271566 (class 2606 OID 22195)
-- Name: chips pk_am_cow_chips; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.chips
    ADD CONSTRAINT pk_am_cow_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271571 (class 2606 OID 22197)
-- Name: markers pk_am_cow_markers; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.markers
    ADD CONSTRAINT pk_am_cow_markers PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271577 (class 2606 OID 22199)
-- Name: projects pk_am_cow_projects; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects
    ADD CONSTRAINT pk_am_cow_projects PRIMARY KEY (project_no);


--
-- TOC entry 271583 (class 2606 OID 22201)
-- Name: projects_permissions pk_am_cow_projects_permissions; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects_permissions
    ADD CONSTRAINT pk_am_cow_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271587 (class 2606 OID 22191)
-- Name: variants pk_cowvariants; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.variants
    ADD CONSTRAINT pk_cowvariants PRIMARY KEY (marker_no);


--
-- TOC entry 271579 (class 2606 OID 22203)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271568 (class 2606 OID 22205)
-- Name: chips u_am_cow_chips_chip_name; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.chips
    ADD CONSTRAINT u_am_cow_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271575 (class 2606 OID 22207)
-- Name: markers2chips u_am_cow_markers2chips_marker_name; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.markers2chips
    ADD CONSTRAINT u_am_cow_markers2chips_marker_name UNIQUE (marker_name, chip_no);


--
-- TOC entry 271581 (class 2606 OID 22209)
-- Name: projects u_am_cow_projects_project_name; Type: CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects
    ADD CONSTRAINT u_am_cow_projects_project_name UNIQUE (project_name);


--
-- TOC entry 271562 (class 1259 OID 22210)
-- Name: fki_am_cow_analyses_project_no; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX fki_am_cow_analyses_project_no ON am_cow.analyses USING btree (project_no);


--
-- TOC entry 271572 (class 1259 OID 22213)
-- Name: i_am_cow_markers2chips_chip_no; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX i_am_cow_markers2chips_chip_no ON am_cow.markers2chips USING btree (chip_no);


--
-- TOC entry 271573 (class 1259 OID 22214)
-- Name: i_am_cow_markers2chips_marker_no; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX i_am_cow_markers2chips_marker_no ON am_cow.markers2chips USING btree (dbsnp_no);


--
-- TOC entry 271569 (class 1259 OID 22215)
-- Name: i_am_cow_markers_chromosome_position; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX i_am_cow_markers_chromosome_position ON am_cow.markers USING btree (chromosome, "position");


--
-- TOC entry 271584 (class 1259 OID 22211)
-- Name: i_cowvariants_chromosome_position; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX i_cowvariants_chromosome_position ON am_cow.variants USING btree (chromosome, "position");


--
-- TOC entry 271585 (class 1259 OID 22212)
-- Name: i_cowvariants_source; Type: INDEX; Schema: am_cow; Owner: postgres
--

CREATE INDEX i_cowvariants_source ON am_cow.variants USING btree (source);


--
-- TOC entry 271588 (class 2606 OID 22216)
-- Name: analyses fk_am_cow_analyses_project_no; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.analyses
    ADD CONSTRAINT fk_am_cow_analyses_project_no FOREIGN KEY (project_no) REFERENCES am_cow.projects(project_no);


--
-- TOC entry 271589 (class 2606 OID 22221)
-- Name: markers2chips fk_am_cow_markers2chips_2_chips; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.markers2chips
    ADD CONSTRAINT fk_am_cow_markers2chips_2_chips FOREIGN KEY (chip_no) REFERENCES am_cow.chips(chip_no);


--
-- TOC entry 271590 (class 2606 OID 22226)
-- Name: markers2chips fk_am_cow_markers2chips_2_markers; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.markers2chips
    ADD CONSTRAINT fk_am_cow_markers2chips_2_markers FOREIGN KEY (dbsnp_no) REFERENCES am_cow.markers(dbsnp_no);


--
-- TOC entry 271591 (class 2606 OID 22231)
-- Name: projects_permissions fk_am_cow_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects_permissions
    ADD CONSTRAINT fk_am_cow_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am_cow.projects(project_no);


--
-- TOC entry 271592 (class 2606 OID 26304)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271593 (class 2606 OID 24792)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am_cow; Owner: postgres
--

ALTER TABLE ONLY am_cow.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am_cow.chips(chip_no);


--
-- TOC entry 271725 (class 0 OID 0)
-- Dependencies: 15
-- Name: SCHEMA am_cow; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am_cow TO PUBLIC;


--
-- TOC entry 271726 (class 0 OID 0)
-- Dependencies: 271
-- Name: TABLE analyses; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.analyses TO PUBLIC;


--
-- TOC entry 271727 (class 0 OID 0)
-- Dependencies: 272
-- Name: TABLE chips; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.chips TO PUBLIC;


--
-- TOC entry 271728 (class 0 OID 0)
-- Dependencies: 355
-- Name: TABLE marker_alleles; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT ALL ON TABLE am_cow.marker_alleles TO genetik;


--
-- TOC entry 271729 (class 0 OID 0)
-- Dependencies: 273
-- Name: TABLE markers; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.markers TO PUBLIC;


--
-- TOC entry 271730 (class 0 OID 0)
-- Dependencies: 274
-- Name: TABLE markers2chips; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.markers2chips TO PUBLIC;


--
-- TOC entry 271731 (class 0 OID 0)
-- Dependencies: 275
-- Name: TABLE projects; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.projects TO PUBLIC;


--
-- TOC entry 271732 (class 0 OID 0)
-- Dependencies: 276
-- Name: TABLE projects_permissions; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.projects_permissions TO PUBLIC;


--
-- TOC entry 271733 (class 0 OID 0)
-- Dependencies: 277
-- Name: SEQUENCE sequence_analyses; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT ALL ON SEQUENCE am_cow.sequence_analyses TO genetik;
GRANT ALL ON SEQUENCE am_cow.sequence_analyses TO PUBLIC;


--
-- TOC entry 271734 (class 0 OID 0)
-- Dependencies: 278
-- Name: SEQUENCE sequence_projects; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT ALL ON SEQUENCE am_cow.sequence_projects TO genetik;
GRANT ALL ON SEQUENCE am_cow.sequence_projects TO PUBLIC;


--
-- TOC entry 271735 (class 0 OID 0)
-- Dependencies: 279
-- Name: TABLE variants; Type: ACL; Schema: am_cow; Owner: postgres
--

GRANT ALL ON TABLE am_cow.variants TO genetik;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_cow.variants TO PUBLIC;


-- Completed on 2022-03-15 14:19:28 CET

--
-- PostgreSQL database dump complete
--

