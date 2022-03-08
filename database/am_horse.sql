--
-- PostgreSQL database dump
--

-- Dumped from database version 12.9
-- Dumped by pg_dump version 12.9

-- Started on 2022-03-15 14:20:08 CET

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
-- TOC entry 22 (class 2615 OID 22388)
-- Name: am_horse; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA am_horse;


ALTER SCHEMA am_horse OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 298 (class 1259 OID 22389)
-- Name: analyses; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.analyses (
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


ALTER TABLE am_horse.analyses OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 22393)
-- Name: chips; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.chips (
    chip_no smallint NOT NULL,
    chip_name character varying(100) NOT NULL,
    manufacturer character varying(100),
    do_not_use boolean
);


ALTER TABLE am_horse.chips OWNER TO postgres;

--
-- TOC entry 362 (class 1259 OID 24868)
-- Name: marker_alleles; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.marker_alleles (
    chip_no smallint NOT NULL,
    marker_id text NOT NULL,
    chromosome smallint NOT NULL,
    "position" integer NOT NULL,
    allele_a character(1) NOT NULL,
    allele_b character(1) NOT NULL
);


ALTER TABLE am_horse.marker_alleles OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 22396)
-- Name: markers; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.markers (
    dbsnp_no numeric(8,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0)
);


ALTER TABLE am_horse.markers OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 22399)
-- Name: markers2chips; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.markers2chips (
    chip_no smallint,
    dbsnp_no integer,
    marker_name character varying(100) NOT NULL,
    remarks character varying(100)
);


ALTER TABLE am_horse.markers2chips OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 22402)
-- Name: projects; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.projects (
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


ALTER TABLE am_horse.projects OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 22407)
-- Name: projects_permissions; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.projects_permissions (
    project_no integer NOT NULL,
    user_login character varying(20) NOT NULL,
    analyse_data boolean NOT NULL,
    query_data boolean NOT NULL
);


ALTER TABLE am_horse.projects_permissions OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 22410)
-- Name: sequence_analyses; Type: SEQUENCE; Schema: am_horse; Owner: postgres
--

CREATE SEQUENCE am_horse.sequence_analyses
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_horse.sequence_analyses OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 22412)
-- Name: sequence_projects; Type: SEQUENCE; Schema: am_horse; Owner: postgres
--

CREATE SEQUENCE am_horse.sequence_projects
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE am_horse.sequence_projects OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 22414)
-- Name: variants; Type: TABLE; Schema: am_horse; Owner: postgres
--

CREATE TABLE am_horse.variants (
    marker_no numeric(10,0) NOT NULL,
    chromosome smallint NOT NULL,
    "position" numeric(9,0) NOT NULL,
    source character(1)
);


ALTER TABLE am_horse.variants OWNER TO postgres;

--
-- TOC entry 271564 (class 2606 OID 22418)
-- Name: analyses pk_am_horse_analyses; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.analyses
    ADD CONSTRAINT pk_am_horse_analyses PRIMARY KEY (analysis_no);


--
-- TOC entry 271566 (class 2606 OID 22420)
-- Name: chips pk_am_horse_chips; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.chips
    ADD CONSTRAINT pk_am_horse_chips PRIMARY KEY (chip_no);


--
-- TOC entry 271571 (class 2606 OID 22422)
-- Name: markers pk_am_horse_markers; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.markers
    ADD CONSTRAINT pk_am_horse_markers PRIMARY KEY (dbsnp_no);


--
-- TOC entry 271577 (class 2606 OID 22424)
-- Name: projects pk_am_horse_projects; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects
    ADD CONSTRAINT pk_am_horse_projects PRIMARY KEY (project_no);


--
-- TOC entry 271583 (class 2606 OID 22426)
-- Name: projects_permissions pk_am_horse_projects_permissions; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects_permissions
    ADD CONSTRAINT pk_am_horse_projects_permissions PRIMARY KEY (project_no, user_login);


--
-- TOC entry 271587 (class 2606 OID 22428)
-- Name: variants pk_horsevariants; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.variants
    ADD CONSTRAINT pk_horsevariants PRIMARY KEY (marker_no);


--
-- TOC entry 271579 (class 2606 OID 22430)
-- Name: projects projects_unique_id_key; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects
    ADD CONSTRAINT projects_unique_id_key UNIQUE (unique_id);


--
-- TOC entry 271568 (class 2606 OID 22432)
-- Name: chips u_am_horse_chips_chip_name; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.chips
    ADD CONSTRAINT u_am_horse_chips_chip_name UNIQUE (chip_name);


--
-- TOC entry 271575 (class 2606 OID 22434)
-- Name: markers2chips u_am_horse_markers2chips_marker_name; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.markers2chips
    ADD CONSTRAINT u_am_horse_markers2chips_marker_name UNIQUE (marker_name, chip_no);


--
-- TOC entry 271581 (class 2606 OID 22436)
-- Name: projects u_am_horse_projects_project_name; Type: CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects
    ADD CONSTRAINT u_am_horse_projects_project_name UNIQUE (project_name);


--
-- TOC entry 271562 (class 1259 OID 22437)
-- Name: fki_am_horse_analyses_project_no; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX fki_am_horse_analyses_project_no ON am_horse.analyses USING btree (project_no);


--
-- TOC entry 271572 (class 1259 OID 22438)
-- Name: i_am_horse_markers2chips_chip_no; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX i_am_horse_markers2chips_chip_no ON am_horse.markers2chips USING btree (chip_no);


--
-- TOC entry 271573 (class 1259 OID 22439)
-- Name: i_am_horse_markers2chips_dbsnp_no; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX i_am_horse_markers2chips_dbsnp_no ON am_horse.markers2chips USING btree (dbsnp_no);


--
-- TOC entry 271569 (class 1259 OID 22440)
-- Name: i_am_horse_markers_chromosome_position; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX i_am_horse_markers_chromosome_position ON am_horse.markers USING btree (chromosome, "position");


--
-- TOC entry 271584 (class 1259 OID 22441)
-- Name: i_horsevariants_chromosome_position; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX i_horsevariants_chromosome_position ON am_horse.variants USING btree (chromosome, "position");


--
-- TOC entry 271585 (class 1259 OID 22442)
-- Name: i_horsevariants_source; Type: INDEX; Schema: am_horse; Owner: postgres
--

CREATE INDEX i_horsevariants_source ON am_horse.variants USING btree (source);


--
-- TOC entry 271588 (class 2606 OID 22443)
-- Name: analyses fk_am_horse_analyses_project_no; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.analyses
    ADD CONSTRAINT fk_am_horse_analyses_project_no FOREIGN KEY (project_no) REFERENCES am_horse.projects(project_no);


--
-- TOC entry 271589 (class 2606 OID 22448)
-- Name: markers2chips fk_am_horse_markers2chips_2_chips; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.markers2chips
    ADD CONSTRAINT fk_am_horse_markers2chips_2_chips FOREIGN KEY (chip_no) REFERENCES am_horse.chips(chip_no);


--
-- TOC entry 271590 (class 2606 OID 22453)
-- Name: markers2chips fk_am_horse_markers2chips_2_markers; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.markers2chips
    ADD CONSTRAINT fk_am_horse_markers2chips_2_markers FOREIGN KEY (dbsnp_no) REFERENCES am_horse.markers(dbsnp_no);


--
-- TOC entry 271591 (class 2606 OID 22458)
-- Name: projects_permissions fk_am_horse_projects_permissions_2_projects; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects_permissions
    ADD CONSTRAINT fk_am_horse_projects_permissions_2_projects FOREIGN KEY (project_no) REFERENCES am_horse.projects(project_no);


--
-- TOC entry 271592 (class 2606 OID 26314)
-- Name: projects_permissions fk_projects_permissions_2_project; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.projects_permissions
    ADD CONSTRAINT fk_projects_permissions_2_project FOREIGN KEY (user_login) REFERENCES am.users(user_login);


--
-- TOC entry 271593 (class 2606 OID 24874)
-- Name: marker_alleles marker_alleles_chip_no_fkey; Type: FK CONSTRAINT; Schema: am_horse; Owner: postgres
--

ALTER TABLE ONLY am_horse.marker_alleles
    ADD CONSTRAINT marker_alleles_chip_no_fkey FOREIGN KEY (chip_no) REFERENCES am_horse.chips(chip_no);


--
-- TOC entry 271725 (class 0 OID 0)
-- Dependencies: 22
-- Name: SCHEMA am_horse; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA am_horse TO PUBLIC;


--
-- TOC entry 271726 (class 0 OID 0)
-- Dependencies: 298
-- Name: TABLE analyses; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.analyses TO PUBLIC;


--
-- TOC entry 271727 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE chips; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.chips TO PUBLIC;


--
-- TOC entry 271728 (class 0 OID 0)
-- Dependencies: 362
-- Name: TABLE marker_alleles; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT ALL ON TABLE am_horse.marker_alleles TO genetik;


--
-- TOC entry 271729 (class 0 OID 0)
-- Dependencies: 300
-- Name: TABLE markers; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.markers TO PUBLIC;


--
-- TOC entry 271730 (class 0 OID 0)
-- Dependencies: 301
-- Name: TABLE markers2chips; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.markers2chips TO PUBLIC;


--
-- TOC entry 271731 (class 0 OID 0)
-- Dependencies: 302
-- Name: TABLE projects; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.projects TO PUBLIC;


--
-- TOC entry 271732 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE projects_permissions; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.projects_permissions TO PUBLIC;


--
-- TOC entry 271733 (class 0 OID 0)
-- Dependencies: 304
-- Name: SEQUENCE sequence_analyses; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT ALL ON SEQUENCE am_horse.sequence_analyses TO genetik;
GRANT ALL ON SEQUENCE am_horse.sequence_analyses TO PUBLIC;


--
-- TOC entry 271734 (class 0 OID 0)
-- Dependencies: 305
-- Name: SEQUENCE sequence_projects; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT ALL ON SEQUENCE am_horse.sequence_projects TO genetik;
GRANT ALL ON SEQUENCE am_horse.sequence_projects TO PUBLIC;


--
-- TOC entry 271735 (class 0 OID 0)
-- Dependencies: 306
-- Name: TABLE variants; Type: ACL; Schema: am_horse; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE am_horse.variants TO PUBLIC;
GRANT ALL ON TABLE am_horse.variants TO genetik;


-- Completed on 2022-03-15 14:20:15 CET

--
-- PostgreSQL database dump complete
--

